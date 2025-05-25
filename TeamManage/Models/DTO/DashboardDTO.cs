namespace TeamManage.Models.DTO
{
    public class GetDashboardIssueDTO
    {
        public int TotalIssue { get; set; }
        public int TotalIssueInProgress { get; set; }
        public int TotalIssueCompleted { get; set; }
        public int TotalIssueNotStarted { get; set; }
    }

    public class GetDashboardTaskDTO
    {
        public int TotalTask { get; set; }
        public int TotalTaskInProgress { get; set; }
        public int TotalTaskCompleted { get; set; }
        public int TotalTaskNotStarted { get; set; }
    }

    public class DashboardDTO
    {
        public GetDashboardTaskDTO TaskStats { get; set; } 
        public GetDashboardIssueDTO IssueStats { get; set; }
    }
}