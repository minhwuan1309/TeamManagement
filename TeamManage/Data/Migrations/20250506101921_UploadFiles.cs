using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TeamManage.Migrations
{
    /// <inheritdoc />
    public partial class UploadFiles : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Image",
                table: "Issues");

            migrationBuilder.CreateTable(
                name: "IssueFile",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    IssueId = table.Column<int>(type: "int", nullable: false),
                    Url = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    UploadedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_IssueFile", x => x.Id);
                    table.ForeignKey(
                        name: "FK_IssueFile_Issues_IssueId",
                        column: x => x.IssueId,
                        principalTable: "Issues",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_IssueFile_IssueId",
                table: "IssueFile",
                column: "IssueId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "IssueFile");

            migrationBuilder.AddColumn<string>(
                name: "Image",
                table: "Issues",
                type: "nvarchar(max)",
                nullable: true);
        }
    }
}
