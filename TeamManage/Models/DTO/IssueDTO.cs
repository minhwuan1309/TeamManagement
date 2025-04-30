namespace TeamManage.Models.DTO
{
    public class IssueDTO
    {
        public int Id { get; set; }
        public int TaskItemId { get; set; }
        public string? Title { get; set; }
        public string? Description { get; set; }
        public ProcessStatus Status { get; set; }
        public string? Image { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
