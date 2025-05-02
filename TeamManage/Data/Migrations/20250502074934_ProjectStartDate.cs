using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TeamManage.Migrations
{
    /// <inheritdoc />
    public partial class ProjectStartDate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Deadline",
                table: "Projects",
                newName: "StartDate");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "StartDate",
                table: "Projects",
                newName: "Deadline");
        }
    }
}
