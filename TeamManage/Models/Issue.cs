using System.Text.Json.Serialization;
using TeamManage.Data;

namespace TeamManage.Models
{
    public class Issue
    {
        // Các field cơ bản
        public int Id { get; set; }
        public int TaskItemId { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }

        // Trạng thái
        public ProcessStatus Status { get; set; }
        public bool IsDeleted { get; set; } = false;

        //User Info
        public string? CreatedById { get; set; }
        public ApplicationUser CreatedBy { get; set; }

        //ICollection
        public ICollection<IssueFile> Files { get; set; } = new List<IssueFile>();

        [JsonIgnore]
        public TaskItem TaskItem { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;
    }
}
