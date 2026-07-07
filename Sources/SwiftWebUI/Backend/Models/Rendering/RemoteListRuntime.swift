//
//  RemoteListRuntime.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 05/07/2026.
//

enum RemoteListRuntime {

    static let scriptID = "swiftwebui-remote-list"

    static let script = """
    (() => {
        function show(element, visible) {
            if (element) {
                element.hidden = !visible;
            }
        }

        function fieldValue(item, path) {
            return String(path)
                .split(".")
                .reduce((value, key) => {
                    if (value == null || typeof value !== "object") {
                        return undefined;
                    }
                    return value[key];
                }, item);
        }

        function fillTemplate(fragment, item) {
            fragment
                .querySelectorAll("[data-swiftwebui-bind-text]")
                .forEach((element) => {
                    const value = fieldValue(item, element.dataset.swiftwebuiBindText);
                    element.textContent = value == null ? "" : String(value);
                });

            fragment
                .querySelectorAll("*")
                .forEach((element) => {
                    Array.from(element.attributes)
                        .filter((attribute) => attribute.name.startsWith("data-swiftwebui-bind-attribute-"))
                        .forEach((attribute) => {
                            const name = attribute.name.replace("data-swiftwebui-bind-attribute-", "");
                            const value = fieldValue(item, attribute.value);
                            if (value == null) {
                                element.removeAttribute(name);
                            } else {
                                element.setAttribute(name, String(value));
                            }
                        });
                });
        }

        async function renderRemoteList(container) {
            const loading = container.querySelector("[data-swiftwebui-remote-loading]");
            const empty = container.querySelector("[data-swiftwebui-remote-empty]");
            const error = container.querySelector("[data-swiftwebui-remote-error]");
            const content = container.querySelector("[data-swiftwebui-remote-content]");
            const templateName = container.dataset.swiftwebuiTemplate;
            const template = Array.from(document.querySelectorAll("template[data-swiftwebui-template]"))
                .find((candidate) => candidate.dataset.swiftwebuiTemplate === templateName);

            show(loading, true);
            show(empty, false);
            show(error, false);

            try {
                if (!content || !template || !template.content) {
                    throw new Error("Missing RemoteList content or template");
                }

                const response = await fetch(container.dataset.swiftwebuiSource, {
                    method: container.dataset.swiftwebuiMethod || "GET"
                });
                if (!response.ok) {
                    throw new Error(`RemoteList request failed with ${response.status}`);
                }

                const data = await response.json();
                if (!Array.isArray(data)) {
                    throw new Error("RemoteList expected a JSON array");
                }

                content.replaceChildren();
                data.forEach((item) => {
                    const fragment = template.content.cloneNode(true);
                    fillTemplate(fragment, item);
                    content.appendChild(fragment);
                });

                show(loading, false);
                show(empty, data.length === 0);
            } catch (exception) {
                show(loading, false);
                show(empty, false);
                show(error, true);
            }
        }

        document.addEventListener("DOMContentLoaded", () => {
            document
                .querySelectorAll("[data-swiftwebui-remote-list]")
                .forEach(renderRemoteList);
        });
    })();
    """
}
