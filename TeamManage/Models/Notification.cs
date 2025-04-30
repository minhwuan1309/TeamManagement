using TeamManage.Data;

namespace TeamManage.Models
{
    public class Notification
    {
        public int Id { get; set; }
        public string ReceiverId { get; set; }
        public string Message { get; set; }
        public bool IsDeleted { get; set; } = false;
        public ApplicationUser Receiver { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;
    }
}
