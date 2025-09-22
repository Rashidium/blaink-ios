//
//  UploadFile.swift
//
//
//  Created by Fatih on 9.12.2022.
//

import Foundation

/// Multipart body file
struct File {
    /// Key of multipart form data.
    var name: String
    /// File name
    var fileName: String
    /// File extension
    var fileExtension: String
    /// Mime type
    var mimeType: String
    /// Data
    var data: Data

    var fileNameWithExtension: String {
        var fileName = fileName
        if !fileExtension.isEmpty {
            fileName.append(".")
            fileName.append(fileExtension)
        }
        return fileName
    }

    /// Initialize multipart File
    /// - Parameters:
    ///   - name: Key of multipart form data.
    ///   - fileName: Name of the file.
    ///   - fileExtension: Extension of the file.
    ///   - mimeType: Mime type.
    ///   - data: Data.
    init(name: String, fileName: String, fileExtension: String, mimeType: String, data: Data) {
        self.name = name
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.mimeType = mimeType
        self.data = data
    }
}
