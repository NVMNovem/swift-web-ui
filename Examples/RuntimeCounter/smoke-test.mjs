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
    if (message.type() === "error") {
        errors.push(message.text());
    }
});
page.on("pageerror", error => {
    errors.push(error.message);
});

try {
    await page.goto(runtimeURL, { waitUntil: "networkidle" });

    const value = page.locator("#app span").nth(1);
    const button = page.getByRole("button", { name: "Increment" });

    if (await value.textContent() !== "0") {
        throw new Error("Expected the initial counter value to be 0");
    }

    await page.evaluate(() => {
        globalThis.swiftWebUIIdentity = {
            root: document.querySelector("#app > *"),
            buttons: [...document.querySelectorAll("button")],
            count: document.querySelectorAll("span")[1],
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
            count: state.count === document.querySelectorAll("span")[1],
            mutations: state.mutations,
        };
    });
    if (!identity.root || !identity.firstButton || !identity.secondButton || !identity.count) {
        throw new Error(`DOM identity changed: ${JSON.stringify(identity)}`);
    }
    if (identity.mutations.length !== 3 || identity.mutations.some(type => type !== "characterData")) {
        throw new Error(`Expected only three text mutations, got: ${identity.mutations.join(", ")}`);
    }
    if (errors.length > 0) {
        throw new Error(`Browser console errors:\n${errors.join("\n")}`);
    }

    console.log("Runtime counter passed: 0 -> 3; root, buttons, and count span retained; only text mutated");
} finally {
    await browser.close();
}
