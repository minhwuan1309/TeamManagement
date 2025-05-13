namespace TeamManage.Models
{
    public enum UserRole
    {
        Admin,
        Dev,
        Tester,
        Viewer
    }

    public enum ProcessStatus
    {
        None,
        InProgress,
        Done
    }

    public enum WorkflowStatus
    {
        None,
        InProgress,
        Testing,
        Done
    }
}
