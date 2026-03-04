-- Seed: regions
INSERT INTO regions (region_name) VALUES
  ('Ahafo'),
  ('Ashanti'),
  ('Bono'),
  ('Bono East'),
  ('Central'),
  ('Eastern'),
  ('Greater Accra'),
  ('North East'),
  ('Northern'),
  ('Oti'),
  ('Savannah'),
  ('Upper East'),
  ('Upper West'),
  ('Volta'),
  ('Western'),
  ('Western North')
ON CONFLICT (region_name) DO NOTHING;
