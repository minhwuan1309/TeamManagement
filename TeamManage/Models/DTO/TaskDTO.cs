﻿namespace TeamManage.Models.DTO
{
    public class TaskDTO
    {
        public int Id { get; set; }
        public int ModuleId { get; set; }
        public string? Title { get; set; }
        public string? Note { get; set; }
        public ProcessStatus Status { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public bool IsDeleted { get; set; }
        public string? AssignedUserId { get; set; }
        public string? AssignedUserName { get; set; }
        public int? CurrentStepId { get; set; }
        public string? CurrentStepName { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class GetModuleWithTaskDTO
    {
        public int Id { get; set; }
        public string? Title { get; set; }
        public ProcessStatus Status { get; set; }
        public string? AssignedUserId { get; set; }
        public string? AssignedUserName { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
    }

    public class TaskCommentDTO
    {
        public int Id { get; set; }
        public int TaskItemId { get; set; }
        public string? UserId { get; set; }
        public string? UserName { get; set; }
        public string? Content { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class CreateTaskCommentDTO
    {
        public int TaskItemId { get; set; }
        public string? Content { get; set; }
    }
}
