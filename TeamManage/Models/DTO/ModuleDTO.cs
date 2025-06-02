using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;
using TeamManage.Data;

namespace TeamManage.Models.DTO
{
    public class ModuleDTO
    {
        public int Id { get; set; }
        public int ProjectId { get; set; }

        public string? Code { get; set; }          // "1.2.3"
        [Required(ErrorMessage = "Tên module là bắt buộc")]
        public string Name { get; set; }

        public int? ParentModuleId { get; set; }  // null nếu là node gốc

        public ProcessStatus Status { get; set; }
        public bool IsDeleted { get; set; }

        public List<MemberDTO>? Members { get; set; } = new();
        public List<GetModuleWithTaskDTO>? Tasks { get; set; } = new();

        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        // Phục vụ tree view (optional)
        public bool IsLeaf => Children == null || Children.Count == 0;
        public List<ModuleDTO>? Children { get; set; } = new();
    }


    public class SimpleModuleDTO
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? Code { get; set; }
        public ProcessStatus Status { get; set; }
        public int MemberCount { get; set; }
        public bool IsDeleted { get; set; }
    }

    public class ModuleTreeDTO
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? Code { get; set; }
        public ProcessStatus Status { get; set; }
        public int MemberCount { get; set; }
        public bool IsDeleted { get; set; }
        public int? ParentModuleId { get; set; }  // null nếu là node gốc

        [JsonIgnore]
        public int ProjectId { get; set; }

        public List<ModuleTreeDTO>? Children { get; set; } = new();
    }

}