//
//  ClientStateRuntime.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/06/2026.
//

enum ClientStateRuntime {
    
    static let scriptID = "swiftwebui-client-state"
    
    static let script = """
    (() => {
        const state = Object.create(null);

        function escaped(value) {
            if (window.CSS && typeof CSS.escape === "function") {
                return CSS.escape(value);
            }

            return String(value).replace(/["\\\\]/g, "\\\\$&");
        }

        function applyState(key, value) {
            state[key] = value;

            document
                .querySelectorAll(`[data-swiftwebui-state-key="${escaped(key)}"][role="tab"]`)
                .forEach((element) => {
                    const selected = element.dataset.swiftwebuiStateValue === value;
                    element.setAttribute("aria-selected", selected ? "true" : "false");
                    element.dataset.swiftwebuiSelected = selected ? "true" : "false";

                    const selectedClass = element.dataset.swiftwebuiSelectedClass;
                    const unselectedClass = element.dataset.swiftwebuiUnselectedClass;
                    element.classList.toggle("swiftwebui-tab-selected", selected);
                    if (selectedClass && unselectedClass) {
                        element.classList.toggle(selectedClass, selected);
                        element.classList.toggle(unselectedClass, !selected);
                    }
                });

            document
                .querySelectorAll(`[data-swiftwebui-state-panel-key="${escaped(key)}"]`)
                .forEach((element) => {
                    const selected = element.dataset.swiftwebuiStatePanelValue === value;
                    element.hidden = !selected;
                });
        }

        document.addEventListener("click", (event) => {
            const target = event.target.closest('[data-swiftwebui-action="set-state"]');
            if (!target) {
                return;
            }

            const key = target.dataset.swiftwebuiStateKey;
            const value = target.dataset.swiftwebuiStateValue;
            if (!key || value == null) {
                return;
            }

            applyState(key, value);
        });
    })();
    """
}
