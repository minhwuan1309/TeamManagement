using TeamManage.Data;

namespace TeamManage.Models
{
    public class TaskComment
    {
        public int Id { get; set; }
        public int TaskItemId { get; set; }
        public string UserId { get; set; }
        public string Content { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        public TaskItem TaskItem { get; set; }
        public ApplicationUser User { get; set; }
    }
}
