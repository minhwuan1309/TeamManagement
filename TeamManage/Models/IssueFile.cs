using System.Text.Json.Serialization;
using TeamManage.Data;

namespace TeamManage.Models
{
    public class IssueFile
    {
        public int Id { get; set; }
        public int IssueId { get; set; }
        public string? Url { get; set; }
        public string? Name { get; set; }
        public string? FileType { get; set; }
        public DateTime UploadedAt { get; set; } = DateTime.Now;

        [JsonIgnore]
        public Issue? Issue { get; set; }
    }
}
