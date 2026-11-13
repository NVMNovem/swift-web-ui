// Opens the Starter's dist/ in headless Chromium, presses its button and checks
// that the count moved. Pressing runs a JSClosure, which reaches Swift through
// JavaScriptKit's `swjs_call_host_function` export, the one an Embedded bundle
// lacked until SwiftWebUIRuntime supplied it.
//
//     node .github/scripts/starter-smoke-test.mjs http://127.0.0.1:8080/ out.png
//
import { chromium } from "playwright";

const [url, screenshotPath = "starter.png"] = process.argv.slice(2);
if (!url) {
    console.error("usage: node starter-smoke-test.mjs <url> [screenshot.png]");
    process.exit(2);
}

const browser = await chromium.launch();
const page = await browser.newPage();
const errors = [];
page.on("pageerror", (error) => errors.push(`pageerror: ${error.message}`));
page.on("console", (message) => {
    console.log(`console.${message.type()}: ${message.text()}`);
    if (message.type() === "error") errors.push(message.text());
});

let failure = null;
try {
    await page.goto(url, { waitUntil: "load" });
    await page.getByText("Pressed 0 times").waitFor({ timeout: 30_000 });
    await page.getByRole("button", { name: "Press" }).click();
    await page.getByText("Pressed 1 times").waitFor({ timeout: 5_000 });
} catch (error) {
    failure = error.message;
}
await page.screenshot({ path: screenshotPath });
await browser.close();

if (failure || errors.length > 0) {
    console.error(failure ?? "The page logged errors.");
    for (const line of errors) console.error(line);
    process.exit(1);
}
console.log("Mounted, pressed, counted.");
