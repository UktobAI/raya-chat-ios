import XCTest
@testable import RayaChatCore

final class MessageQueueTests: XCTestCase {

    func testEnqueueAndFlush() {
        let queue = MessageQueue()
        queue.enqueue("msg1")
        queue.enqueue("msg2")
        queue.enqueue("msg3")

        XCTAssertEqual(queue.count, 3)
        XCTAssertFalse(queue.isEmpty)

        let flushed = queue.flushAll()
        XCTAssertEqual(flushed, ["msg1", "msg2", "msg3"])
        XCTAssertTrue(queue.isEmpty)
        XCTAssertEqual(queue.count, 0)
    }

    func testFlushEmptyQueue() {
        let queue = MessageQueue()
        let flushed = queue.flushAll()
        XCTAssertTrue(flushed.isEmpty)
    }

    func testClear() {
        let queue = MessageQueue()
        queue.enqueue("msg1")
        queue.enqueue("msg2")
        queue.clear()

        XCTAssertTrue(queue.isEmpty)
        XCTAssertEqual(queue.count, 0)
    }

    func testFlushThenEnqueue() {
        let queue = MessageQueue()
        queue.enqueue("msg1")
        _ = queue.flushAll()

        queue.enqueue("msg2")
        let flushed = queue.flushAll()
        XCTAssertEqual(flushed, ["msg2"])
    }

    func testOrderPreserved() {
        let queue = MessageQueue()
        for i in 0..<100 {
            queue.enqueue("msg-\(i)")
        }
        let flushed = queue.flushAll()
        XCTAssertEqual(flushed.count, 100)
        XCTAssertEqual(flushed.first, "msg-0")
        XCTAssertEqual(flushed.last, "msg-99")
    }
}
