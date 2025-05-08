using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TeamManage.Migrations
{
    /// <inheritdoc />
    public partial class UploadFileTypes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "FileType",
                table: "IssueFile",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FileType",
                table: "IssueFile");
        }
    }
}
