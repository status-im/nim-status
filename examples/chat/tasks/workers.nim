import # chat libs
  ./workers/worker_pool, ./workers/worker_thread, ./workers/worker

export worker_pool, worker_thread, worker

type WorkerKind* = enum pool, thread
