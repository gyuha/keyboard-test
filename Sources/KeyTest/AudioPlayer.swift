import AVFoundation
import Foundation

/// 소스 노드 하나로 여러 음을 섞어 재생한다.
final class AudioPlayer {
    private let engine = AVAudioEngine()
    private let lock = NSLock()
    private var voices: [(samples: [Float], position: Int)] = []
    private(set) var sampleRate: Double = 44100

    func start() {
        let rate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        if rate > 0 { sampleRate = rate }
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        let node = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList in
            self?.render(frames: Int(frameCount), into: audioBufferList)
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
        } catch {
            FileHandle.standardError.write(Data("오디오 엔진을 시작하지 못했습니다: \(error)\n".utf8))
        }
    }

    func play(samples: [Float]) {
        lock.lock()
        if voices.count >= 24 { voices.removeFirst() }
        voices.append((samples, 0))
        lock.unlock()
    }

    private func render(frames: Int, into list: UnsafeMutablePointer<AudioBufferList>) {
        let buffers = UnsafeMutableAudioBufferListPointer(list)
        for buffer in buffers {
            guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
            for i in 0..<frames { data[i] = 0 }
            lock.lock()
            for v in voices.indices {
                let remaining = voices[v].samples.count - voices[v].position
                let count = min(frames, remaining)
                for i in 0..<count { data[i] += voices[v].samples[voices[v].position + i] }
                voices[v].position += count
            }
            voices.removeAll { $0.position >= $0.samples.count }
            lock.unlock()
        }
    }
}
