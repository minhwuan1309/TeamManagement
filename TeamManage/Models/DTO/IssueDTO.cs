namespace TeamManage.Models.DTO
{
    public class IssueDTO
    {
        public int Id { get; set; }
        public int TaskItemId { get; set; }
        public string? Title { get; set; }
        public string? Description { get; set; }
        public ProcessStatus Status { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class IssueDetailDTO
    {
        public int Id { get; set; }
        public string? Title { get; set; }
        public string? Description { get; set; }
        public ProcessStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        public string? CreatedByName { get; set; }
        public List<IssueFileDTO> Files { get; set; } = new List<IssueFileDTO>();
    }

    public class IssueFileDTO
    {
        public string? Url { get; set; }
        public string? Name { get; set; }
        public string? FileType { get; set; }
    }

}
