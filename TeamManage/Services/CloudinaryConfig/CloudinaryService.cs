using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using Microsoft.Extensions.Configuration;

namespace TeamManage.Services.CloudinaryConfig
{
    public class CloudinaryService
    {
        private readonly Cloudinary _cloudinary;

        public CloudinaryService(IConfiguration config)
        {
            var account = new Account(
                config["CloudinarySettings:CloudName"],
                config["CloudinarySettings:ApiKey"],
                config["CloudinarySettings:ApiSecret"]
            );
            _cloudinary = new Cloudinary(account);
            
        }

        public async Task<string?> UploadImageAsync(IFormFile file)
        {
            if(file == null || file.Length == 0) return null;

            await using var stream = file.OpenReadStream();
            var updateParams = new ImageUploadParams
            {
                File = new FileDescription(file.FileName, stream),
                UseFilename = true,
                UniqueFilename = true,
                Overwrite = true
            };
            
            var result = await _cloudinary.UploadAsync(updateParams);
            return result.SecureUrl?.ToString();
        }
    }
    
}
