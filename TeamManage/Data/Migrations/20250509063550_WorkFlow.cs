using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TeamManage.Migrations
{
    /// <inheritdoc />
    public partial class WorkFlow : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Workflows_Projects_ProjectId",
                table: "Workflows");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "WorkflowSteps");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "WorkflowSteps");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "WorkflowStepApprovals");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "WorkflowStepApprovals");

            migrationBuilder.AddColumn<DateTime>(
                name: "CompletedAt",
                table: "WorkflowSteps",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "WorkflowSteps",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AlterColumn<int>(
                name: "ProjectId",
                table: "Workflows",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AddColumn<int>(
                name: "ModuleId",
                table: "Workflows",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "CurrentStepId",
                table: "TaskItems",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "WorkflowId",
                table: "Modules",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_TaskItems_CurrentStepId",
                table: "TaskItems",
                column: "CurrentStepId");

            migrationBuilder.CreateIndex(
                name: "IX_Modules_WorkflowId",
                table: "Modules",
                column: "WorkflowId");

            migrationBuilder.AddForeignKey(
                name: "FK_Modules_Workflows_WorkflowId",
                table: "Modules",
                column: "WorkflowId",
                principalTable: "Workflows",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull); 

            migrationBuilder.AddForeignKey(
                name: "FK_TaskItems_WorkflowSteps_CurrentStepId",
                table: "TaskItems",
                column: "CurrentStepId",
                principalTable: "WorkflowSteps",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Workflows_Projects_ProjectId",
                table: "Workflows",
                column: "ProjectId",
                principalTable: "Projects",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_TaskItems_WorkflowSteps_CurrentStepId",
                table: "TaskItems");

            migrationBuilder.DropForeignKey(
                name: "FK_Workflows_Projects_ProjectId",
                table: "Workflows");

            migrationBuilder.DropIndex(
                name: "IX_TaskItems_CurrentStepId",
                table: "TaskItems");

            migrationBuilder.DropColumn(
                name: "CompletedAt",
                table: "WorkflowSteps");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "WorkflowSteps");

            migrationBuilder.DropColumn(
                name: "ModuleId",
                table: "Workflows");

            migrationBuilder.DropColumn(
                name: "CurrentStepId",
                table: "TaskItems");

            migrationBuilder.DropColumn(
                name: "WorkflowId",
                table: "Modules");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "WorkflowSteps",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "WorkflowSteps",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "WorkflowStepApprovals",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "WorkflowStepApprovals",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AlterColumn<int>(
                name: "ProjectId",
                table: "Workflows",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Workflows_Projects_ProjectId",
                table: "Workflows",
                column: "ProjectId",
                principalTable: "Projects",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
