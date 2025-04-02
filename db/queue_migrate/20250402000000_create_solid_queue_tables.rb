# frozen_string_literal: true

class CreateSolidQueueTables < ActiveRecord::Migration[7.1]
  def change
    create_table "solid_queue_blocked_executions" do |t|
      t.references :job, null: false, index: false
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.string :concurrency_key, null: false
      t.datetime :expires_at, null: false
      t.timestamps

      t.index %i[expires_at concurrency_key job_id], name: "blocked_executions_for_release"
      t.index %i[concurrency_key job_id], unique: true
    end

    create_table "solid_queue_claimed_executions" do |t|
      t.references :job, null: false, index: { unique: true }
      t.bigint :process_id
      t.datetime :created_at, null: false

      t.index %i[process_id job_id], unique: true
    end

    create_table "solid_queue_failed_executions" do |t|
      t.references :job, null: false, index: { unique: true }
      t.text :error
      t.datetime :created_at, null: false
    end

    create_table "solid_queue_jobs" do |t|
      t.string :queue_name, null: false
      t.string :class_name, null: false
      t.text :arguments
      t.integer :priority, default: 0, null: false
      t.string :active_job_id
      t.datetime :scheduled_at
      t.datetime :finished_at
      t.string :concurrency_key
      t.timestamps

      t.index %i[active_job_id], unique: true
      t.index %i[finished_at], where: "finished_at IS NULL"
      t.index %i[queue_name scheduled_at], where: "finished_at IS NULL"
    end

    create_table "solid_queue_pauses" do |t|
      t.string :queue_name, null: false
      t.datetime :created_at, null: false

      t.index %i[queue_name], unique: true
    end

    create_table "solid_queue_processes" do |t|
      t.string :kind, null: false
      t.datetime :last_heartbeat_at, null: false
      t.bigint :supervisor_id
      t.integer :pid, null: false
      t.string :hostname
      t.text :metadata
      t.timestamps

      t.index %i[last_heartbeat_at kind], name: "index_solid_queue_processes_for_cleanup"
    end

    create_table "solid_queue_ready_executions" do |t|
      t.references :job, null: false, index: { unique: true }
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.datetime :created_at, null: false

      t.index %i[priority created_at job_id], name: "index_solid_queue_ready_executions_for_polling"
      t.index %i[queue_name priority created_at job_id], name: "index_solid_queue_ready_executions_for_queue_polling"
    end

    create_table "solid_queue_recurring_executions" do |t|
      t.references :task, null: false, index: { unique: true }
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.datetime :scheduled_at, null: false
      t.timestamps

      t.index %i[scheduled_at], name: "index_solid_queue_recurring_executions_for_polling"
    end

    create_table "solid_queue_recurring_tasks" do |t|
      t.string :class_name, null: false
      t.string :queue_name
      t.integer :priority, default: 0, null: false
      t.text :arguments
      t.string :cron
      t.datetime :last_run_at
      t.datetime :created_at, null: false

      t.index %i[cron], unique: true
      t.index %i[class_name], unique: true
    end

    create_table "solid_queue_scheduled_executions" do |t|
      t.references :job, null: false, index: { unique: true }
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.datetime :scheduled_at, null: false
      t.timestamps

      t.index %i[scheduled_at], name: "index_solid_queue_scheduled_executions_for_polling"
    end

    create_table "solid_queue_semaphores" do |t|
      t.string :key, null: false
      t.integer :value, default: 1, null: false
      t.datetime :expires_at, null: false
      t.timestamps

      t.index %i[key value], unique: true
      t.index %i[expires_at], name: "index_solid_queue_semaphores_for_cleanup"
    end
  end
end 