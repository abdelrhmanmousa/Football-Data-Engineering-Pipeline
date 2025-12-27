# THE STATE MACHINE (The Graph)
resource "aws_sfn_state_machine" "pipeline" {
  name     = "${var.project_name}-orchestrator"
  role_arn = aws_iam_role.sfn_role.arn

  definition = jsonencode({
    StartAt = "ParallelIngestion",
    States = {
      # 1. Run 3 Python Jobs at the same time
      ParallelIngestion = {
        Type = "Parallel",
        Next = "RunDBT",
        Branches = [
          {
            StartAt = "IngestFixtures",
            States = {
              IngestFixtures = {
                Type     = "Task",
                Resource = "arn:aws:states:::ecs:runTask.sync",
                Parameters = {
                  LaunchType     = "FARGATE",
                  Cluster        = aws_ecs_cluster.main.arn,
                  TaskDefinition = aws_ecs_task_definition.ingestion_task.arn,
                  NetworkConfiguration = {
                    AwsvpcConfiguration = {
                      Subnets        = data.aws_subnets.default.ids
                      SecurityGroups = [aws_security_group.ecs_sg.id]
                      AssignPublicIp = "ENABLED"
                    }
                  },
                  Overrides = {
                    ContainerOverrides = [{
                      Name = "ingestion-container",
                      # This overrides the CMD in Dockerfile to run specific job
                      Command = ["--job", "fixtures"]
                    }]
                  }
                },
                End = true
              }
            }
          },
          {
            StartAt = "IngestPlayers",
            States = {
              IngestPlayers = {
                Type     = "Task",
                Resource = "arn:aws:states:::ecs:runTask.sync",
                Parameters = {
                  LaunchType     = "FARGATE",
                  Cluster        = aws_ecs_cluster.main.arn,
                  TaskDefinition = aws_ecs_task_definition.ingestion_task.arn,
                  NetworkConfiguration = {
                    AwsvpcConfiguration = {
                      Subnets        = data.aws_subnets.default.ids
                      SecurityGroups = [aws_security_group.ecs_sg.id]
                      AssignPublicIp = "ENABLED"
                    }
                  },
                  Overrides = {
                    ContainerOverrides = [{
                      Name    = "ingestion-container",
                      Command = ["--job", "players"]
                    }]
                  }
                },
                End = true
              }
            }
          },
          # Add Standings here similarly...
          {
            StartAt = "IngestStandings",
            States = {
              IngestStandings = {
                Type     = "Task",
                Resource = "arn:aws:states:::ecs:runTask.sync",
                Parameters = {
                  LaunchType     = "FARGATE",
                  Cluster        = aws_ecs_cluster.main.arn,
                  TaskDefinition = aws_ecs_task_definition.ingestion_task.arn,
                  NetworkConfiguration = {
                    AwsvpcConfiguration = {
                      Subnets        = data.aws_subnets.default.ids
                      SecurityGroups = [aws_security_group.ecs_sg.id]
                      AssignPublicIp = "ENABLED"
                    }
                  },
                  Overrides = {
                    ContainerOverrides = [{
                      Name    = "ingestion-container",
                      Command = ["--job", "standings"]
                    }]
                  }
                },
                End = true
              }
            }
          }
        ]
      },
      # 2. Run dbt after ingestion is done
      RunDBT = {
        Type     = "Task",
        Resource = "arn:aws:states:::ecs:runTask.sync",
        Parameters = {
          LaunchType     = "FARGATE",
          Cluster        = aws_ecs_cluster.main.arn,
          TaskDefinition = aws_ecs_task_definition.analytics_task.arn,
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets        = data.aws_subnets.default.ids
              SecurityGroups = [aws_security_group.ecs_sg.id]
              AssignPublicIp = "ENABLED"
            }
          },
          Overrides = {
            ContainerOverrides = [{
              Name    = "analytics-container",
              Command = ["/bin/sh", "-c", "dbt build --target snowflake"]
              ## run this to force full refresh for the first time
              ##Command = ["/bin/sh", "-c", "dbt build --target snowflake","--full-refresh"]
            }]
          }
        },
        End = true
      }
    }
  })
}