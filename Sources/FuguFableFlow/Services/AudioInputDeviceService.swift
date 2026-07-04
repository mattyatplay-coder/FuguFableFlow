import CoreAudio
import Foundation

struct AudioInputDevice: Identifiable, Equatable {
    let id: AudioDeviceID
    let name: String
    let isBuiltIn: Bool
    let isDefault: Bool

    var displayName: String {
        isDefault ? "\(name) (default)" : name
    }
}

enum AudioInputDeviceError: LocalizedError {
    case noInputDevices
    case noBuiltInMicrophone
    case coreAudio(OSStatus)

    var errorDescription: String? {
        switch self {
        case .noInputDevices:
            "No microphone input devices were found."
        case .noBuiltInMicrophone:
            "No built-in microphone input was found."
        case .coreAudio(let status):
            "Audio input setup failed: \(status)"
        }
    }
}

final class AudioInputDeviceService {
    func inputDevices() throws -> [AudioInputDevice] {
        DiagnosticLog.audio.info("inputDevices begin")
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size
        )
        guard status == noErr else { throw AudioInputDeviceError.coreAudio(status) }

        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = Array(repeating: AudioDeviceID(), count: count)
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceIDs
        )
        guard status == noErr else { throw AudioInputDeviceError.coreAudio(status) }

        let defaultID = defaultInputDeviceID()
        let devices = deviceIDs.compactMap { deviceID -> AudioInputDevice? in
            guard hasInputChannels(deviceID) else { return nil }
            return AudioInputDevice(
                id: deviceID,
                name: deviceName(deviceID),
                isBuiltIn: isBuiltIn(deviceID),
                isDefault: deviceID == defaultID
            )
        }

        guard !devices.isEmpty else { throw AudioInputDeviceError.noInputDevices }
        let summary = devices.map { "\($0.id):\($0.name):builtIn=\($0.isBuiltIn):default=\($0.isDefault)" }.joined(separator: ", ")
        DiagnosticLog.audio.info("inputDevices result \(summary, privacy: .public)")
        return devices.sorted { lhs, rhs in
            if lhs.isBuiltIn != rhs.isBuiltIn {
                return lhs.isBuiltIn && !rhs.isBuiltIn
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    func preferBuiltInMicrophone() throws -> AudioInputDevice {
        DiagnosticLog.audio.info("preferBuiltInMicrophone begin")
        let devices = try inputDevices()
        guard let builtIn = devices.first(where: \.isBuiltIn) else {
            DiagnosticLog.audio.error("preferBuiltInMicrophone no built-in device")
            throw AudioInputDeviceError.noBuiltInMicrophone
        }
        try setDefaultInputDevice(builtIn.id)
        DiagnosticLog.audio.info("preferBuiltInMicrophone set default id=\(builtIn.id, privacy: .public) name=\(builtIn.name, privacy: .public)")
        return AudioInputDevice(
            id: builtIn.id,
            name: builtIn.name,
            isBuiltIn: true,
            isDefault: true
        )
    }

    func defaultInputDeviceDescription() -> String {
        guard let id = defaultInputDeviceID(), id != kAudioObjectUnknown else {
            return "No default microphone"
        }
        return deviceName(id)
    }

    private func defaultInputDeviceID() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID()
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        return status == noErr ? deviceID : nil
    }

    private func setDefaultInputDevice(_ deviceID: AudioDeviceID) throws {
        DiagnosticLog.audio.info("setDefaultInputDevice id=\(deviceID, privacy: .public)")
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var mutableDeviceID = deviceID
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            size,
            &mutableDeviceID
        )
        guard status == noErr else { throw AudioInputDeviceError.coreAudio(status) }
    }

    private func hasInputChannels(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size)
        guard status == noErr, size > 0 else { return false }

        let rawPointer = UnsafeMutableRawPointer.allocate(
            byteCount: Int(size),
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer { rawPointer.deallocate() }

        let bufferList = rawPointer.bindMemory(to: AudioBufferList.self, capacity: 1)
        status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, bufferList)
        guard status == noErr else { return false }

        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        return buffers.contains { $0.mNumberChannels > 0 }
    }

    private func deviceName(_ deviceID: AudioDeviceID) -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var unmanagedName: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &unmanagedName)
        guard status == noErr, let unmanagedName else { return "Unknown Microphone" }
        return unmanagedName.takeRetainedValue() as String
    }

    private func isBuiltIn(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var transportType: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &transportType)
        if status == noErr, transportType == kAudioDeviceTransportTypeBuiltIn {
            return true
        }

        let name = deviceName(deviceID).lowercased()
        return name.contains("built-in") || name.contains("macbook")
    }
}
