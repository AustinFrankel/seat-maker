import Foundation
import Compression

enum CompressionError: Error {
    case failed
}

struct LZFSECompression {
    static func compress(_ data: Data) throws -> Data {
        return try perform(data: data, operation: COMPRESSION_STREAM_ENCODE, algorithm: COMPRESSION_LZFSE)
    }
    
    static func decompress(_ data: Data) throws -> Data {
        return try perform(data: data, operation: COMPRESSION_STREAM_DECODE, algorithm: COMPRESSION_LZFSE)
    }
    
    private static func perform(data: Data, operation: compression_stream_operation, algorithm: compression_algorithm) throws -> Data {
        // Use simple buffer encode/decode APIs for reliability
        if operation == COMPRESSION_STREAM_ENCODE {
            return try data.withUnsafeBytes { (src: UnsafeRawBufferPointer) in
                guard let srcPtr = src.baseAddress?.assumingMemoryBound(to: UInt8.self) else { throw CompressionError.failed }
                var dstCapacity = max(1024, data.count / 2 + 64)
                for _ in 0..<8 {
                    let dstPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCapacity)
                    defer { dstPtr.deallocate() }
                    let written = compression_encode_buffer(dstPtr, dstCapacity, srcPtr, data.count, nil, algorithm)
                    if written > 0 {
                        return Data(bytes: dstPtr, count: written)
                    }
                    dstCapacity *= 2
                }
                throw CompressionError.failed
            }
        } else {
            return try data.withUnsafeBytes { (src: UnsafeRawBufferPointer) in
                guard let srcPtr = src.baseAddress?.assumingMemoryBound(to: UInt8.self) else { throw CompressionError.failed }
                var dstCapacity = max(2048, data.count * 4)
                for _ in 0..<8 {
                    let dstPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCapacity)
                    defer { dstPtr.deallocate() }
                    let written = compression_decode_buffer(dstPtr, dstCapacity, srcPtr, data.count, nil, algorithm)
                    if written > 0 {
                        return Data(bytes: dstPtr, count: written)
                    }
                    dstCapacity *= 2
                }
                throw CompressionError.failed
            }
        }
    }
}


