## 重要

作業をする前にdocs/TODO.mdを確認して、作業内容を把握してください。
作業内容の粒度が荒い場合は1つのタスクを具体的なタスクに分割して、そのタスクの下の階層としてTODO.mdを更新してください。
作業は上から順番に取り組んでください。
作業が終了した場合はTODO.mdのタスクにチェックをしてください。

## ファイル階層の説明
.
├── Pipfile: パッケージ管理ファイル
├── Pipfile.lock: パッケージロックファイル
├── README.md: プロジェクトの概要
├── alembic: alambicのマイグレーションスクリプト
│   ├── env.py
│   ├── script.py.mako
│   └── versions
├── alembic.ini: alembicの設定ファイル
├── app: アプリケーションのコード
│   ├── app_enum.py: Enumクラス
│   ├── app_pattern.py
│   ├── application: メインのアプリケーションコード
│   ├── error.py
│   ├── infrastructure
│   ├── job_*.py: ジョブのコード
│   ├── logger.py
│   ├── trigger_*.py: S3などからのトリガーを受けるコード
│   └── util
├── aws: AWSのcloudformationのテンプレート
├── buildspec: AWS CodeBuildのビルドスペックファイル
├── deploy
│   ├── deploy_pf_api.py
│   ├── deploy_pf_job.py
│   ├── deploy_pf_trigger.py
│   ├── deploy_tr.py
│   ├── deploy_tr_api.py
│   ├── deploy_tr_job.py
│   ├── deploy_tr_new.py
│   └── deploy_tr_trigger.py
├── deploy_api_admin.py
├── deploy_api_driver.py
├── deploy_api_system_linkage.py
├── deploy_api_without_auth.py
├── deploy_async_download_excel.py
├── deploy_job_alkiller_send_mail_for_user.py
├── deploy_job_announce_viewable_driver_count.py
├── deploy_job_begin_end_reservation_notification.py
├── deploy_job_check_ses.py
├── deploy_job_clear_input_history.py
├── deploy_job_contract_salesforce.py
├── deploy_job_insert_alkiller_result.py
├── deploy_job_invalid_reservation_notification.py
├── deploy_job_remove_freekey_grant.py
├── deploy_job_remove_organization.py
├── deploy_job_remove_user.py
├── deploy_job_report_remind_notification.py
├── deploy_job_resend_email_for_user_registration.py
├── deploy_job_save_log_vehicle_number.py
├── deploy_job_save_statistic_reservation.py
├── deploy_job_signout_mfa.py
├── deploy_job_update_reservation_status.py
├── deploy_new_environment.py
├── deploy_new_lambda_20241025.py
├── deploy_new_lambda_20241206.py
├── deploy_trigger_csv_replace.py
├── deploy_trigger_csv_upload.py
├── deploy_trigger_message_process.py
├── deploy_trigger_mfa_message.py
├── deploy_trigger_mfa_reset.py
├── docs: バックエンド用のドキュメント
│   ├── Makefile
│   ├── TODO.md: ドキュメント作成のTODOリスト
│   ├── build
│   └── source: ドキュメントのソース
├── get-list-ses-templates.sh
├── keys
│   └── presigned_url_private.pem
├── openapi
│   └── spec: OpenAPIのスキーマ
├── pyproject.toml
├── pytest.ini
├── resource_policy_system_linkage.json
├── scripts: スクリプト
│   ├── compose.yaml
│   ├── create_layer_lock.py
│   ├── create_test_data.py
│   ├── dbData_v5.12
│   ├── github_actions
│   ├── import_mysql_dump.sh
│   ├── run_api_admin.sh
│   ├── run_api_driver.sh
│   ├── run_api_linkage.sh
│   ├── run_api_manage.sh
│   ├── run_vm_api_admin.sh
│   ├── run_vm_api_driver.sh
│   ├── set_env.sh
│   ├── set_root_env.sh
│   └── set_vm_env.sh
├── setup.cfg
├── tests: テストコード
│   ├── __init__.py
│   ├── app
│   ├── client_proxy.py
│   ├── create_test_data.py
│   ├── data_model
│   ├── load_test
│   ├── test.sh
│   ├── tr-test-cov.sh
│   └── tr-test.sh
├── update_all_lambda.py
├── update_doc.py
├── update_job_alcohol_reminder.py
├── update_job_auto_cancel_reservation.py
├── update_job_battery_low.py
├── update_job_clear_input_history.py
├── update_job_contract_salesforce.py
├── update_job_driver_license.py
├── update_job_exclusive_reminder.py
├── update_job_invalid_driver_license.py
├── update_job_invalid_vehicle_license.py
├── update_job_vehicle_license.py
├── update_trigger_driver_license.py
├── update_trigger_invalid_reservation.py
├── uploads
│   └── template
├── vm_api_runner.sh
├── zappa_**.yaml: zappaの設定ファイル