INSERT INTO gs_handoff.handoff_notes
  (scholar_name, cohort, priority, summary, owner, due_date, status, tags)
VALUES
  ('Amina Noor', '2026 Spring', 'High', 'Finalize FAFSA verification and confirm missing tax transcript.', 'S. Patel', '2026-02-18', 'Open', ARRAY['financial', 'verification']),
  ('Luis Mendoza', '2026 Spring', 'Medium', 'Schedule second mentor introduction; prior mentor unavailable.', 'J. Brooks', '2026-02-20', 'In Progress', ARRAY['mentor', 'scheduling']),
  ('Chloe Kim', '2026 Spring', 'Critical', 'Address housing insecurity update and connect to emergency grant.', 'M. Alvarez', '2026-02-12', 'Blocked', ARRAY['wellbeing', 'emergency']),
  ('Tariq Rahman', '2025 Fall', 'Low', 'Collect internship acceptance letter for employer match verification.', 'K. Owens', '2026-02-25', 'Open', ARRAY['career', 'documentation']),
  ('Rosa Delgado', '2025 Fall', 'High', 'Confirm travel stipend receipts and submit reimbursement packet.', 'N. Singh', '2026-02-16', 'Open', ARRAY['travel', 'stipend']);
