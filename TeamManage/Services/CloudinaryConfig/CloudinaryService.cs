using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;

namespace TeamManage.Services.CloudinaryConfig
{
    public class CloudinaryService
    {
        private readonly Cloudinary _cloudinary;
        private readonly ILogger<CloudinaryService> _logger;
        private static readonly HashSet<string> SupportedRawExtensions = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".txt", ".csv", ".zip", ".rar"
        };
        private const long MaxFileSize = 10 * 1024 * 1024; // 10MB

        public CloudinaryService(IConfiguration config, ILogger<CloudinaryService> logger)
        {
            var account = new Account(
                config["CloudinarySettings:CloudName"],
                config["CloudinarySettings:ApiKey"],
                config["CloudinarySettings:ApiSecret"]
            );
            _cloudinary = new Cloudinary(account);
            _logger = logger;
        }

        public async Task<(string url, string type)?> UploadFileAsync(IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                _logger.LogWarning("No file provided or file is empty.");
                return null;
            }

            if (file.Length > MaxFileSize)
            {
                _logger.LogError($"File {file.FileName} exceeds maximum size of {MaxFileSize / (1024 * 1024)}MB.");
                return null;
            }

            string extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            await using var stream = file.OpenReadStream();

            try
            {
                // Ảnh
                if (new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif" }.Contains(extension))
                {
                    var imageParams = new ImageUploadParams
                    {
                        File = new FileDescription(file.FileName, stream),
                        UseFilename = true,
                        UniqueFilename = true,
                        Overwrite = true,
                        Folder = "TeamManage"
                    };

                    var result = await _cloudinary.UploadAsync(imageParams);
                    return (result.SecureUrl.ToString(), "image");
                }

                // Video
                if (new[] { ".mp4", ".mov", ".avi", ".mkv" }.Contains(extension))
                {
                    var videoParams = new VideoUploadParams
                    {
                        File = new FileDescription(file.FileName, stream),
                        UseFilename = true,
                        UniqueFilename = true,
                        Overwrite = true,
                        Folder = "TeamManage"
                    };

                    var result = await _cloudinary.UploadAsync(videoParams);
                    return (result.SecureUrl.ToString(), "video");
                }

                // File: Word, Excel, PDF, TXT, ZIP, RAR
                if (SupportedRawExtensions.Contains(extension))
                {
                    var rawParams = new RawUploadParams
                    {
                        File = new FileDescription(file.FileName, stream),
                        UseFilename = true,
                        UniqueFilename = true,
                        Overwrite = true,
                        Folder = "TeamManage",  
                    };

                    var result = await _cloudinary.UploadAsync(rawParams);
                    _logger.LogInformation($"Uploaded raw file {file.FileName} to {result.SecureUrl}");

                    // Lưu ý: Đảm bảo bật "Allow delivery of PDF and ZIP files" trong Cloudinary Settings > Security
                    // để tránh lỗi 404 khi truy cập tệp ZIP/RAR/PDF.
                    return (result.SecureUrl.ToString(), "file");
                }

                _logger.LogWarning($"Unsupported file extension: {extension}");
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error uploading file {file.FileName}");
                return null;
            }
        }
    }
}