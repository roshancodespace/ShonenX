# Downloads

The download manager orchestrates background fetching for offline consumption of Anime episodes and Manga chapters.

## Architecture

Downloads execute asynchronously and independently of the active UI, managed within [`lib/features/downloads/`](https://github.com/roshancodespace/shonenx/tree/main/lib/features/downloads/).

1.  **Queueing:** A user queues an episode. A `DownloadTask` record is inserted into Isar with a `pending` state.
2.  **Execution:** The `DownloadService` polls for pending tasks. When a slot opens, it initiates the network stream.
3.  **File Management:** Media is streamed directly to the device's persistent storage. For Manga, images are downloaded into a structured directory or archived (e.g., CBZ).
4.  **Completion:** The `DownloadTask` is marked `completed` and the local file URI is recorded. 

## Integration

When the user requests to play media, the engine queries the `DownloadTask` database. If a completed task exists, the engine overrides the remote URL with the local file path, entirely bypassing network resolution and tracking synchronization for that specific stream request.
