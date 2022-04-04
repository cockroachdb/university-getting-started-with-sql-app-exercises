CREATE TABLE movr_vehicles.vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_type STRING NOT NULL,
    purchase_date DATE NOT NULL DEFAULT current_date(),
    serial_number STRING NOT NULL,
    make STRING NOT NULL,
    model STRING NOT NULL,
    year INT2 NOT NULL,
    color STRING NOT NULL,
    description STRING
);