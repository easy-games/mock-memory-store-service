import "@rbxts/types";
/*
	Since MockMemoryStoreService is 
	designed to mock MemoryStoreService,
	we can just use its typings.
*/
declare const MemoryStoreWrapper: MemoryStoreService;
export = MemoryStoreWrapper;
