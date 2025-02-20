import Flutter
import AVFoundation
import MobileCoreServices

public class VidKitPlugin: NSObject, FlutterPlugin {
    private var exporter: AVAssetExportSession? = nil
    private var _channel: FlutterMethodChannel? = nil
    private var stopCommand = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "vid_kit", binaryMessenger: registrar.messenger())
        let instance = VidKitPlugin()
        instance._channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? Dictionary<String, Any>
        
        switch call.method {
            case "getVideoDuration":
                let path = args!["path"] as! String
                getVideoDuration(path: path, result: result)
                            
            case "trimVideo":
                let inputPath = args!["inputPath"] as! String
                let outputPath = args!["outputPath"] as! String
                let startMs = args!["startMs"] as! Int
                let endMs = args!["endMs"] as! Int
                trimVideo(inputPath: inputPath, outputPath: outputPath, startMs: startMs, endMs: endMs, result: result)
            case "getThumbnail":
                let path = args!["path"] as! String
                let quality = args!["quality"] as! NSNumber
                let position = args!["position"] as! NSNumber
                getThumbnail(path, quality, position, result)
            case "compressVideo":
                let path = args!["path"] as! String
                let quality = args!["quality"] as! NSNumber
                let includeAudio = args!["includeAudio"] as? Bool
                let frameRate = args!["frameRate"] as? Int
                compressVideo(path, quality, includeAudio, frameRate, result)
            case "cancelCompression":
                cancelCompression(result)
            default:
            result(FlutterMethodNotImplemented)
        }
    }
    private func getVideoDuration(path: String, result: @escaping FlutterResult) {
        let url = getPathUrl(path)
        let asset = getVideoAsset(url)
        let duration = asset.duration.seconds * 1000
        result(duration)
    }

    private func trimVideo(inputPath: String, outputPath: String, startMs: Int, endMs: Int, result: @escaping FlutterResult) {
        let startTime = CMTimeMake(value: Int64(startMs), timescale: 1000)
        let endTime = CMTimeMake(value: Int64(endMs), timescale: 1000)
        
        let inputURL = URL(fileURLWithPath: inputPath)
        let outputURL = URL(fileURLWithPath: outputPath)
        
        // Criando o asset do vídeo
        let asset = AVAsset(url: inputURL)
        
        // Definindo o intervalo de tempo do corte
        let timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        
        // Criando o export session
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.timeRange = timeRange
        
        // Exportando o vídeo de forma assíncrona
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                // Se a exportação for bem-sucedida, retorne o caminho do arquivo de saída
                result(outputPath)
            case .failed, .cancelled:
                // Se houver erro, retorne a mensagem de erro
                if let error = exportSession.error {
                    result(FlutterError(code: "EXPORT_FAILED", message: error.localizedDescription, details: nil))
                } else {
                    result(FlutterError(code: "EXPORT_CANCELLED", message: "A exportação foi cancelada.", details: nil))
                }
            default:
                break
            }
        }
    }

    private func getThumbnail(_ path: String,_ quality: NSNumber,_ position: NSNumber,_ result: FlutterResult) {
         if let bitmap = getBitMap(path,quality,position,result) {
            result(bitmap)
        }
    }

    private func getBitMap(_ path: String,_ quality: NSNumber,_ position: NSNumber,_ result: FlutterResult)-> Data?  {
        let url = getPathUrl(path)
        let asset = getVideoAsset(url)
        guard let track = getTrack(asset) else { return nil }
        
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        
        let timeScale = CMTimeScale(track.nominalFrameRate)
        let time = CMTimeMakeWithSeconds(Float64(truncating: position),preferredTimescale: timeScale)
        guard let img = try? assetImgGenerate.copyCGImage(at:time, actualTime: nil) else {
            return nil
        }
        let thumbnail = UIImage(cgImage: img)
        let compressionQuality = CGFloat(0.01 * Double(truncating: quality))
        return thumbnail.jpegData(compressionQuality: compressionQuality)
    }


    private func compressVideo(_ path: String,_ quality: NSNumber,_ includeAudio: Bool?,_ frameRate: Int?,
                               _ result: @escaping FlutterResult) {
        let sourceVideoUrl = getPathUrl(path)
        let sourceVideoType = "mp4"
        
        let sourceVideoAsset = getVideoAsset(sourceVideoUrl)
        let sourceVideoTrack = getTrack(sourceVideoAsset)

        let uuid = NSUUID()
        let compressionUrl =
        getPathUrl("\(basePath())/\(getFileName(path))\(uuid.uuidString).\(sourceVideoType)")

        let timescale = sourceVideoAsset.duration.timescale
                
        let cmStartTime = CMTimeMakeWithSeconds(0, preferredTimescale: timescale)
        let videoDuration = sourceVideoAsset.duration
        let timeRange: CMTimeRange = CMTimeRangeMake(start: cmStartTime, duration: videoDuration)
        
        let isIncludeAudio = includeAudio != nil ? includeAudio! : true
        
        let session = getComposition(isIncludeAudio, timeRange, sourceVideoTrack!)
        
        let exporter = AVAssetExportSession(asset: session, presetName: getExportPreset(quality))!
        
        exporter.outputURL = compressionUrl
        exporter.outputFileType = AVFileType.mp4
        exporter.shouldOptimizeForNetworkUse = true
        
        if frameRate != nil {
            let videoComposition = AVMutableVideoComposition(propertiesOf: sourceVideoAsset)
            videoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate!))
            exporter.videoComposition = videoComposition
        }
        
        if !isIncludeAudio {
            exporter.timeRange = timeRange
        }

        let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateProgress),
                                         userInfo: exporter, repeats: true)
                        
        exporter.exportAsynchronously(completionHandler: {
            timer.invalidate()
            if(self.stopCommand) {
                self.stopCommand = false
                return result(path)
            }
            result(compressionUrl.path)
        })
        self.exporter = exporter
    }

    @objc private func updateProgress(timer:Timer) {
        let asset = timer.userInfo as! AVAssetExportSession
        if(!stopCommand) {
           self._channel!.invokeMethod("updateProgress", arguments: asset.progress )
        }
    }

    private func getExportPreset(_ quality: NSNumber)->String {
        switch(quality) {
        case 0:
            return AVAssetExportPresetLowQuality    
        case 1:
            return AVAssetExportPresetMediumQuality
        case 2:
            return AVAssetExportPresetHighestQuality
        case 3:
            return AVAssetExportPreset1280x720 // Boa qualidade com tamanho reduzido
        case 4:
            return AVAssetExportPreset1920x1080 // Full HD (maior qualidade, maior tamanho)
        default:
            return AVAssetExportPresetMediumQuality
        }
        
    }

    private func getComposition(_ isIncludeAudio: Bool,_ timeRange: CMTimeRange, _ sourceVideoTrack: AVAssetTrack)->AVAsset {
        let composition = AVMutableComposition()
        if !isIncludeAudio {
            let compressionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
            compressionVideoTrack!.preferredTransform = sourceVideoTrack.preferredTransform
            try? compressionVideoTrack!.insertTimeRange(timeRange, of: sourceVideoTrack, at: CMTime.zero)
        } else {
            return sourceVideoTrack.asset!
        }
       
        return composition    
    }
    
    private func cancelCompression(_ result: FlutterResult) {
        stopCommand = true
        exporter?.cancelExport()
        result("")
    }

    private func getPathUrl(_ path: String)->URL {
        return URL(fileURLWithPath: excludeFileProtocol(path))
    }

    private func excludeFileProtocol(_ path: String)->String {
        return path.replacingOccurrences(of: "file://", with: "")
    }

    private func getVideoAsset(_ url:URL)->AVURLAsset {
        return AVURLAsset(url: url)
    }

    private func getTrack(_ asset: AVURLAsset)->AVAssetTrack? {
        var track : AVAssetTrack? = nil
        let group = DispatchGroup()
        group.enter()
        asset.loadValuesAsynchronously(forKeys: ["tracks"], completionHandler: {
            var error: NSError? = nil;
            let status = asset.statusOfValue(forKey: "tracks", error: &error)
            if (status == .loaded) {
                track = asset.tracks(withMediaType: AVMediaType.video).first
            }
            group.leave()
        })
        group.wait()
        return track
    }

    private func basePath()->String {
        let fileManager = FileManager.default
        let path = "\(NSTemporaryDirectory())video_compress"
        do {
            if !fileManager.fileExists(atPath: path) {
                try! fileManager.createDirectory(atPath: path,
                                                 withIntermediateDirectories: true, attributes: nil)
            }
        }
        return path
    }

    private func getFileName(_ path: String)->String {
        return stripFileExtension((path as NSString).lastPathComponent)
    }

    private func stripFileExtension(_ fileName:String)->String {
        var components = fileName.components(separatedBy: ".")
        if components.count > 1 {
            components.removeLast()
            return components.joined(separator: ".")
        } else {
            return fileName
        }
    }
}
