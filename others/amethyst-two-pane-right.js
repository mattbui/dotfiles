function layout() {
    return {
        name: "Two Pane Right",
        initialState: {
            mainPaneCount: 1,
            mainPaneRatio: 0.5
        },
        commands: {
            command1: {
                description: "Shrink main pane",
                updateState: (state) => {
                    return { ...state, mainPaneRatio: Math.max(0.1, state.mainPaneRatio - 0.05) };
                }
            },
            command2: {
                description: "Expand main pane",
                updateState: (state) => {
                    return { ...state, mainPaneRatio: Math.min(0.9, state.mainPaneRatio + 0.05) };
                }
            }
        },
        getFrameAssignments: (windows, screenFrame, state) => {
            const mainPaneCount = Math.min(state.mainPaneCount, windows.length);
            const secondaryPaneCount = windows.length - mainPaneCount;
            const hasSecondaryPane = secondaryPaneCount > 0;

            const mainPaneWindowHeight = screenFrame.height / mainPaneCount;
            const secondaryPaneWindowHeight = screenFrame.height;

            const mainPaneWindowWidth = hasSecondaryPane? Math.round(screenFrame.width * state.mainPaneRatio) : screenFrame.width;
            const secondaryPaneWindowWidth = screenFrame.width - mainPaneWindowWidth

            return windows.reduce((frames, window, index) => {
                const isMain = index < mainPaneCount;
                let frame;
                if (isMain) {
                    frame = {
                        x: screenFrame.x + secondaryPaneWindowWidth,
                        y: screenFrame.y,
                        width: mainPaneWindowWidth,
                        height: mainPaneWindowHeight
                    };
                } else {
                    frame = {
                        x: screenFrame.x,
                        y: screenFrame.y,
                        width: secondaryPaneWindowWidth,
                        height: secondaryPaneWindowHeight
                    }
                }
                return { ...frames, [window.id]: frame };
            }, {});
        }
    };
}
