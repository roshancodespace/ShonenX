# Watch Screen Architecture

This document outlines the architecture of the Watch Screen module in ShonenX.

## Overview

The Watch Screen is responsible for playing anime episodes and managing user interactions with the video player. It has been refactored to improve maintainability, performance, and code organization.

## Components

### Main Components

- **WatchScreen**: The main screen component that orchestrates all the other components.
- **VideoPlayerView**: Handles the video player UI and controls.
- **EpisodesPanel**: Displays the list of episodes and allows the user to select them.
- **LoadingOverlay**: Shows loading indicators and error messages.

### Services

- **ThumbnailService**: Handles generating thumbnails from video frames.
- **WatchProgressService**: Manages saving and loading watch progress.

## State Management

The Watch Screen uses Riverpod for state management with the following providers:

- **watchProvider**: Manages the overall state of the watch screen.
- **playerProvider**: Manages the media player state.
- **controllerProvider**: Manages the video controller.
- **playerStateProvider**: Manages the current playback state.
- **playerSettingsProvider**: Manages player settings.

## Flow

1. User navigates to the Watch Screen
2. The screen initializes and fetches episodes
3. When an episode is selected, the player loads the video
4. Progress is saved periodically
5. Thumbnails are generated for the continue watching section

## Improvements

The refactoring includes the following improvements:

1. **Separation of Concerns**: Logic has been separated into dedicated services.
2. **Improved Error Handling**: Better error handling and user feedback.
3. **Performance Optimization**: Reduced unnecessary rebuilds.
4. **Code Organization**: Better organization of code into smaller, focused components.
5. **Maintainability**: Improved documentation and code structure.

## Future Improvements

Potential future improvements include:

1. Implementing a more robust thumbnail generation system
2. Adding support for offline playback
3. Improving subtitle handling
4. Adding more player customization options
