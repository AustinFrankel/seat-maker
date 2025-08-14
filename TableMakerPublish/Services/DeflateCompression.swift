import Foundation
import Compression

enum DeflateCompressionError: Error { case failed }

struct DeflateCompression {
    static func compress(_ data: Data) throws -> Data {
        return try perform(data: data, operation: COMPRESSION_STREAM_ENCODE, algorithm: COMPRESSION_ZLIB)
    }
    static func decompress(_ data: Data) throws -> Data {
        return try perform(data: data, operation: COMPRESSION_STREAM_DECODE, algorithm: COMPRESSION_ZLIB)
    }
    private static func perform(data: Data, operation: compression_stream_operation, algorithm: compression_algorithm) throws -> Data {
        let bufferSize = max(64 * 1024, data.count * 2)
        var destination = Data(count: bufferSize)
        var result = Data()
        try data.withUnsafeBytes { (srcPtrRaw: UnsafeRawBufferPointer) in
            guard let srcPtr = srcPtrRaw.baseAddress?.assumingMemoryBound(to: UInt8.self) else { throw DeflateCompressionError.failed }
            let destinationCapacity = destination.count
            return try destination.withUnsafeMutableBytes { (dstPtrRaw: UnsafeMutableRawBufferPointer) in
                guard let dstPtr = dstPtrRaw.baseAddress?.assumingMemoryBound(to: UInt8.self) else { throw DeflateCompressionError.failed }
                var stream = compression_stream(
                    dst_ptr: dstPtr,
                    dst_size: destinationCapacity,
                    src_ptr: srcPtr,
                    src_size: data.count,
                    state: nil
                )
                guard compression_stream_init(&stream, operation, algorithm) != COMPRESSION_STATUS_ERROR else {
                    throw DeflateCompressionError.failed
                }
                defer { compression_stream_destroy(&stream) }
                while true {
                    let status = compression_stream_process(&stream, Int32(COMPRESSION_STREAM_FINALIZE.rawValue))
                    switch status {
                    case COMPRESSION_STATUS_OK, COMPRESSION_STATUS_END:
                        let written = destinationCapacity - stream.dst_size
                        if written > 0 { result.append(dstPtr, count: written) }
                        stream.dst_ptr = dstPtr
                        stream.dst_size = destinationCapacity
                        if status == COMPRESSION_STATUS_END { return }
                    default:
                        throw DeflateCompressionError.failed
                    }
                }
            }
        }
        return result
    }
}


