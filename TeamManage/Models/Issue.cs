using System.Text.Json.Serialization;

namespace TeamManage.Models
{
    public class Issue
    {
        public int Id { get; set; }
        public int TaskItemId { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public ProcessStatus Status { get; set; }
        public ICollection<IssueFile> Files { get; set; } = new List<IssueFile>();
        public bool IsDeleted { get; set; } = false;
        [JsonIgnore]
        public TaskItem TaskItem { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;
    }
}
