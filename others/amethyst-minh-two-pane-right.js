function layout() {
  return {
    name: "Minh's Two Pane Right",
    initialState: {
      mainPaneRatio: 0.7, // Default 80% for single window, configurable for multi-window
    },
    commands: {
      shrinkMain: {
        description: "Shrink main pane",
        updateState: (state) => {
          const step = 0.025; // 2.5% step
          const newRatio = Math.max(0.1, state.mainPaneRatio - step);
          return { ...state, mainPaneRatio: newRatio };
        },
      },
      expandMain: {
        description: "Expand main pane",
        updateState: (state) => {
          const step = 0.025; // 2.5% step
          const newRatio = Math.min(0.9, state.mainPaneRatio + step);
          return { ...state, mainPaneRatio: newRatio };
        },
      },
    },
    recommendMainPaneRatio: (ratio, state) => {
      return { ...state, mainPaneRatio: ratio };
    },
    getFrameAssignments: (windows, screenFrame, state) => {
      if (windows.length === 0) {
        return {};
      }

      const mainPaneCount = 1; // Always 1 main pane
      const secondaryPaneCount = windows.length - mainPaneCount;
      const hasSecondaryPane = secondaryPaneCount > 0;

      // Single window case - center it with configurable width
      if (windows.length === 1) {
        return windows.reduce((frames, window) => {
          const windowWidth = screenFrame.width * state.mainPaneRatio;
          const windowX = screenFrame.x + (screenFrame.width - windowWidth) / 2;

          const frame = {
            x: windowX,
            y: screenFrame.y,
            width: windowWidth,
            height: screenFrame.height,
            isMain: true,
            unconstrainedDimension: "horizontal",
          };

          return { ...frames, [window.id]: frame };
        }, {});
      }

      // Multi-window case
      const mainPaneWindowHeight = screenFrame.height;
      const secondaryPaneWindowHeight = screenFrame.height;

      const mainPaneWindowWidth = hasSecondaryPane
        ? Math.round(screenFrame.width * state.mainPaneRatio)
        : screenFrame.width;
      const secondaryPaneWindowWidth = screenFrame.width - mainPaneWindowWidth;

      return windows.reduce((frames, window, index) => {
        const isMain = index < mainPaneCount;
        let frame;

        if (isMain) {
          frame = {
            x: screenFrame.x + secondaryPaneWindowWidth,
            y: screenFrame.y,
            width: mainPaneWindowWidth,
            height: mainPaneWindowHeight,
            isMain: true,
            unconstrainedDimension: "horizontal",
          };
        } else {
          // All secondary windows stack on top of each other (same position)
          frame = {
            x: screenFrame.x,
            y: screenFrame.y,
            width: secondaryPaneWindowWidth,
            height: secondaryPaneWindowHeight,
            isMain: false,
            unconstrainedDimension: "horizontal",
          };
        }

        return { ...frames, [window.id]: frame };
      }, {});
    },
  };
}
