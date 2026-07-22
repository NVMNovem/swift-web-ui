import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const playwrightPath = process.env.PLAYWRIGHT_PATH ?? "playwright";
const chromePath = process.env.CHROME_PATH;
const runtimeURL = process.env.SWIFTWEBUI_RUNTIME_URL ?? "http://127.0.0.1:8080/";
const { chromium } = require(playwrightPath);

const browser = await chromium.launch({
    headless: true,
    ...(chromePath ? { executablePath: chromePath } : {}),
});

const page = await browser.newPage();
const errors = [];

page.on("console", message => {
    if (message.type() === "error" || message.type() === "warning") {
        errors.push(message.text());
    }
});
page.on("pageerror", error => {
    errors.push(error.message);
});

try {
    await page.goto(runtimeURL, { waitUntil: "networkidle" });

    const value = page.locator("#runtime-count");
    const button = page.getByRole("button", { name: "Increment" });

    const resourceResults = await page.evaluate(async () => {
        const [stylesheet, asset] = await Promise.all([
            fetch("style.css"),
            fetch("assets/runtime-fixture.svg"),
        ]);
        const section = document.querySelector("#runtime-styled-section");
        const image = document.querySelector('img[src="assets/runtime-fixture.svg"]');
        await image.decode();
        const computed = getComputedStyle(section);
        const rules = [...document.styleSheets].flatMap(sheet => [...sheet.cssRules]);
        return {
            stylesheetStatus: stylesheet.status,
            assetStatus: asset.status,
            stylesheetCount: document.styleSheets.length,
            declaredLinkCount: document.querySelectorAll('head link[rel="stylesheet"][href="style.css"]').length,
            borderStyle: computed.borderTopStyle,
            accent: computed.getPropertyValue("--runtime-accent").trim(),
            background: computed.backgroundColor,
            hasResponsiveMedia: rules.some(rule => rule.cssText.includes("max-width: 860px")),
            hasDarkMedia: rules.some(rule => rule.cssText.includes("prefers-color-scheme: dark")),
            imageWidth: image.naturalWidth,
            imageHeight: image.naturalHeight,
        };
    });
    if (resourceResults.stylesheetStatus !== 200 || resourceResults.assetStatus !== 200) {
        throw new Error(`Resource request failed: ${JSON.stringify(resourceResults)}`);
    }
    if (resourceResults.stylesheetCount < 1 || resourceResults.declaredLinkCount !== 1) {
        throw new Error(`Stylesheet was not installed exactly once: ${JSON.stringify(resourceResults)}`);
    }
    if (resourceResults.borderStyle !== "solid" || !resourceResults.accent || resourceResults.background === "rgba(0, 0, 0, 0)") {
        throw new Error(`Named rules or CSS variables did not resolve: ${JSON.stringify(resourceResults)}`);
    }
    if (!resourceResults.hasResponsiveMedia || !resourceResults.hasDarkMedia) {
        throw new Error(`Expected media-query rules were not present: ${JSON.stringify(resourceResults)}`);
    }
    if (resourceResults.imageWidth === 0 || resourceResults.imageHeight === 0) {
        throw new Error(`Fixture image has no natural dimensions: ${JSON.stringify(resourceResults)}`);
    }

    const section = page.locator("#runtime-styled-section");
    const backgroundBeforeHover = await section.evaluate(node => getComputedStyle(node).backgroundColor);
    await section.hover();
    await page.waitForTimeout(160);
    const backgroundAfterHover = await section.evaluate(node => getComputedStyle(node).backgroundColor);
    if (backgroundBeforeHover === backgroundAfterHover) {
        throw new Error("Pseudo-class hover rule did not affect computed styling");
    }

    if (await value.textContent() !== "0") {
        throw new Error("Expected the initial counter value to be 0");
    }

    await page.evaluate(() => {
        globalThis.swiftWebUIIdentity = {
            root: document.querySelector("#app > *"),
            buttons: [...document.querySelectorAll("button")],
            count: document.querySelector("#runtime-count"),
            stylesheet: document.querySelector('head link[rel="stylesheet"][href="style.css"]'),
            mutations: [],
        };
        const observer = new MutationObserver(records => {
            globalThis.swiftWebUIIdentity.mutations.push(...records.map(record => record.type));
        });
        observer.observe(document.querySelector("#app"), {
            subtree: true,
            childList: true,
            attributes: true,
            characterData: true,
        });
        globalThis.swiftWebUIIdentity.observer = observer;
    });

    for (let click = 0; click < 3; click += 1) {
        await button.click();
    }

    if (await value.textContent() !== "3") {
        throw new Error("Expected the counter value to be 3 after three clicks");
    }
    const identity = await page.evaluate(() => {
        const state = globalThis.swiftWebUIIdentity;
        state.observer.disconnect();
        return {
            root: state.root === document.querySelector("#app > *"),
            firstButton: state.buttons[0] === document.querySelectorAll("button")[0],
            secondButton: state.buttons[1] === document.querySelectorAll("button")[1],
            count: state.count === document.querySelector("#runtime-count"),
            stylesheet: state.stylesheet === document.querySelector('head link[rel="stylesheet"][href="style.css"]'),
            stylesheetCount: document.querySelectorAll('head link[rel="stylesheet"][href="style.css"]').length,
            mutations: state.mutations,
        };
    });
    if (!identity.root || !identity.firstButton || !identity.secondButton || !identity.count || !identity.stylesheet) {
        throw new Error(`DOM identity changed: ${JSON.stringify(identity)}`);
    }
    if (identity.stylesheetCount !== 1) {
        throw new Error(`Stylesheet duplicated during reconciliation: ${JSON.stringify(identity)}`);
    }
    if (identity.mutations.length !== 3 || identity.mutations.some(type => type !== "characterData")) {
        throw new Error(`Expected only three text mutations, got: ${identity.mutations.join(", ")}`);
    }
    if (errors.length > 0) {
        throw new Error(`Browser console errors:\n${errors.join("\n")}`);
    }

    console.log("Runtime counter passed: stylesheet rules/variables/media/hover and asset loaded; 0 -> 3; DOM and stylesheet identity retained; only count text mutated");
} finally {
    await browser.close();
}
