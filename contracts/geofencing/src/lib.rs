//! FuelAnchor Geofencing Contract
//!
//! Manages geographic boundaries and validation for:
//! - Fuel station locations
//! - Fleet operating corridors
//! - Cross-border route verification

#![no_std]

use soroban_sdk::{
    contract, contractimpl, contracttype, Address, BytesN, Env, Map, String, Symbol, Vec,
};

/// Geographic point with micro-degree precision
#[derive(Clone, Debug, PartialEq)]
#[contracttype]
pub struct GeoPoint {
    /// Latitude in micro-degrees (actual_degrees * 1_000_000)
    pub lat: i64,
    /// Longitude in micro-degrees (actual_degrees * 1_000_000)
    pub lng: i64,
}

/// Circular geofence (most common for stations)
#[derive(Clone, Debug, PartialEq)]
#[contracttype]
pub struct CircularZone {
    pub id: BytesN<32>,
    pub name: String,
    pub center: GeoPoint,
    pub radius_meters: u32,
    pub zone_type: ZoneType,
    pub is_active: bool,
    pub created_at: u64,
}

/// Polygon geofence (for corridors and complex zones)
#[derive(Clone, Debug, PartialEq)]
#[contracttype]
pub struct PolygonZone {
    pub id: BytesN<32>,
    pub name: String,
    /// Vertices of the polygon (minimum 3 points)
    pub vertices: Vec<GeoPoint>,
    pub zone_type: ZoneType,
    pub is_active: bool,
    pub created_at: u64,
}

/// Zone types for different use cases
#[derive(Clone, Debug, PartialEq)]
#[contracttype]
pub enum ZoneType {
    /// Fuel station location
    Station,
    /// Fleet operational area
    FleetArea,
    /// Cross-border corridor (e.g., Mombasa-Kampala)
    Corridor,
    /// Restricted area (blacklisted)
    Restricted,
    /// Country boundary
    Country,
    /// City/Urban area
    Urban,
}

/// Validation result for geofence checks
#[derive(Clone, Debug, PartialEq)]
#[contracttype]
pub struct ValidationResult {
    pub is_valid: bool,
    pub zone_id: BytesN<32>,
    pub zone_name: String,
    pub distance_from_center: u32,
    pub validation_time: u64,
}

/// Corridor definition (route between two points with buffer)
#[derive(Clone, Debug, PartialEq)]
#[contracttype]
pub struct Corridor {
    pub id: BytesN<32>,
    pub name: String,
    pub start_point: GeoPoint,
    pub end_point: GeoPoint,
    /// Waypoints along the corridor
    pub waypoints: Vec<GeoPoint>,
    /// Buffer zone width in meters (distance from route centerline)
    pub buffer_meters: u32,
    pub is_active: bool,
    pub created_at: u64,
}

/// East African country codes
#[derive(Clone, Debug, PartialEq)]
#[contracttype]
pub enum EACCountry {
    Kenya,
    Uganda,
    Tanzania,
    Rwanda,
    Burundi,
    SouthSudan,
    DRC,
}

/// Data keys for storage
#[derive(Clone)]
#[contracttype]
pub enum DataKey {
    Admin,
    CircularZone(BytesN<32>),
    PolygonZone(BytesN<32>),
    Corridor(BytesN<32>),
    ZoneCount,
    CorridorCount,
    CountryBounds(EACCountry),
    FleetZones(Address),
    StationZone(Address),
}

/// Constants for distance calculations
const EARTH_RADIUS_METERS: i64 = 6_371_000;
const MICRO_DEGREES: i64 = 1_000_000;

/// Approximate meters per degree at equator
const METERS_PER_DEGREE: i64 = 111_320;

#[contract]
pub struct Geofencing;

#[contractimpl]
impl Geofencing {
    /// Initialize the geofencing contract
    pub fn initialize(env: Env, admin: Address) {
        if env.storage().instance().has(&DataKey::Admin) {
            panic!("Already initialized");
        }
        
        env.storage().instance().set(&DataKey::Admin, &admin);
        env.storage().instance().set(&DataKey::ZoneCount, &0u64);
        env.storage().instance().set(&DataKey::CorridorCount, &0u64);
    }

    /// Create a circular geofence zone
    pub fn create_circular_zone(
        env: Env,
        admin: Address,
        zone_id: BytesN<32>,
        name: String,
        center: GeoPoint,
        radius_meters: u32,
        zone_type: ZoneType,
    ) {
        admin.require_auth();
        Self::require_admin(&env, &admin);

        let zone = CircularZone {
            id: zone_id.clone(),
            name,
            center,
            radius_meters,
            zone_type,
            is_active: true,
            created_at: env.ledger().timestamp(),
        };

        env.storage().persistent().set(&DataKey::CircularZone(zone_id.clone()), &zone);

        let zone_count: u64 = env.storage().instance().get(&DataKey::ZoneCount).unwrap_or(0);
        env.storage().instance().set(&DataKey::ZoneCount, &(zone_count + 1));

        env.events().publish(
            (Symbol::new(&env, "zone_created"), zone_id),
            zone.name,
        );
    }

    /// Create a polygon geofence zone
    pub fn create_polygon_zone(
        env: Env,
        admin: Address,
        zone_id: BytesN<32>,
        name: String,
        vertices: Vec<GeoPoint>,
        zone_type: ZoneType,
    ) {
        admin.require_auth();
        Self::require_admin(&env, &admin);

        if vertices.len() < 3 {
            panic!("Polygon must have at least 3 vertices");
        }

        let zone = PolygonZone {
            id: zone_id.clone(),
            name,
            vertices,
            zone_type,
            is_active: true,
            created_at: env.ledger().timestamp(),
        };

        env.storage().persistent().set(&DataKey::PolygonZone(zone_id.clone()), &zone);

        let zone_count: u64 = env.storage().instance().get(&DataKey::ZoneCount).unwrap_or(0);
        env.storage().instance().set(&DataKey::ZoneCount, &(zone_count + 1));

        env.events().publish(
            (Symbol::new(&env, "polygon_zone_created"), zone_id),
            zone.name,
        );
    }

    /// Create a transport corridor
    pub fn create_corridor(
        env: Env,
        admin: Address,
        corridor_id: BytesN<32>,
        name: String,
        start_point: GeoPoint,
        end_point: GeoPoint,
        waypoints: Vec<GeoPoint>,
        buffer_meters: u32,
    ) {
        admin.require_auth();
        Self::require_admin(&env, &admin);

        let corridor = Corridor {
            id: corridor_id.clone(),
            name,
            start_point,
            end_point,
            waypoints,
            buffer_meters,
            is_active: true,
            created_at: env.ledger().timestamp(),
        };

        env.storage().persistent().set(&DataKey::Corridor(corridor_id.clone()), &corridor);

        let corridor_count: u64 = env.storage().instance().get(&DataKey::CorridorCount).unwrap_or(0);
        env.storage().instance().set(&DataKey::CorridorCount, &(corridor_count + 1));

        env.events().publish(
            (Symbol::new(&env, "corridor_created"), corridor_id),
            corridor.name,
        );
    }

    /// Check if a point is within a circular zone
    pub fn validate_circular_zone(
        env: Env,
        zone_id: BytesN<32>,
        point: GeoPoint,
    ) -> ValidationResult {
        let zone: CircularZone = env.storage().persistent()
            .get(&DataKey::CircularZone(zone_id.clone()))
            .expect("Zone not found");

        if !zone.is_active {
            return ValidationResult {
                is_valid: false,
                zone_id,
                zone_name: zone.name,
                distance_from_center: 0,
                validation_time: env.ledger().timestamp(),
            };
        }

        let distance = Self::calculate_distance(&zone.center, &point);
        let is_valid = distance <= zone.radius_meters;

        ValidationResult {
            is_valid,
            zone_id,
            zone_name: zone.name,
            distance_from_center: distance,
            validation_time: env.ledger().timestamp(),
        }
    }

    /// Check if a point is within a corridor
    pub fn validate_corridor(
        env: Env,
        corridor_id: BytesN<32>,
        point: GeoPoint,
    ) -> bool {
        let corridor: Corridor = env.storage().persistent()
            .get(&DataKey::Corridor(corridor_id))
            .expect("Corridor not found");

        if !corridor.is_active {
            return false;
        }

        // Check distance to the corridor path
        // First check distance to start-end line
        let mut min_distance = Self::point_to_line_distance(
            &point,
            &corridor.start_point,
            &corridor.end_point,
        );

        // Check distance to each segment between waypoints
        if !corridor.waypoints.is_empty() {
            let mut prev_point = corridor.start_point.clone();
            for i in 0..corridor.waypoints.len() {
                let waypoint = corridor.waypoints.get(i).unwrap();
                let dist = Self::point_to_line_distance(&point, &prev_point, &waypoint);
                if dist < min_distance {
                    min_distance = dist;
                }
                prev_point = waypoint;
            }
            // Check last segment to end point
            let dist = Self::point_to_line_distance(&point, &prev_point, &corridor.end_point);
            if dist < min_distance {
                min_distance = dist;
            }
        }

        min_distance <= corridor.buffer_meters
    }

    /// Calculate distance between two points (in meters)
    pub fn calculate_distance(point1: &GeoPoint, point2: &GeoPoint) -> u32 {
        // Simplified Euclidean distance calculation
        // For more accuracy, implement full Haversine formula
        let lat_diff = (point1.lat - point2.lat).abs();
        let lng_diff = (point1.lng - point2.lng).abs();

        // Convert micro-degrees to meters (approximate)
        let lat_meters = (lat_diff * METERS_PER_DEGREE) / MICRO_DEGREES;
        let lng_meters = (lng_diff * METERS_PER_DEGREE) / MICRO_DEGREES;

        // Euclidean distance
        let distance_squared = lat_meters * lat_meters + lng_meters * lng_meters;
        
        // Integer square root
        Self::isqrt(distance_squared as u64) as u32
    }

    /// Calculate point to line segment distance
    fn point_to_line_distance(point: &GeoPoint, line_start: &GeoPoint, line_end: &GeoPoint) -> u32 {
        // Vector from line_start to line_end
        let line_dx = line_end.lng - line_start.lng;
        let line_dy = line_end.lat - line_start.lat;

        // Length squared of the line segment
        let line_len_sq = line_dx * line_dx + line_dy * line_dy;

        if line_len_sq == 0 {
            // Line is a point
            return Self::calculate_distance(point, line_start);
        }

        // Vector from line_start to point
        let point_dx = point.lng - line_start.lng;
        let point_dy = point.lat - line_start.lat;

        // Project point onto line, clamping to segment
        let t = ((point_dx * line_dx + point_dy * line_dy) * 1000 / line_len_sq).max(0).min(1000);

        // Closest point on segment
        let closest = GeoPoint {
            lat: line_start.lat + (line_dy * t / 1000),
            lng: line_start.lng + (line_dx * t / 1000),
        };

        Self::calculate_distance(point, &closest)
    }

    /// Integer square root helper
    fn isqrt(n: u64) -> u64 {
        if n == 0 {
            return 0;
        }
        let mut x = n;
        let mut y = (x + 1) / 2;
        while y < x {
            x = y;
            y = (x + n / x) / 2;
        }
        x
    }

    /// Assign zones to a fleet operator
    pub fn assign_fleet_zones(
        env: Env,
        admin: Address,
        fleet_operator: Address,
        zone_ids: Vec<BytesN<32>>,
    ) {
        admin.require_auth();
        Self::require_admin(&env, &admin);

        env.storage().persistent().set(&DataKey::FleetZones(fleet_operator.clone()), &zone_ids);

        env.events().publish(
            (Symbol::new(&env, "fleet_zones_assigned"), fleet_operator),
            zone_ids.len(),
        );
    }

    /// Check if a location is valid for a fleet's operations
    pub fn validate_fleet_location(
        env: Env,
        fleet_operator: Address,
        point: GeoPoint,
    ) -> bool {
        let zone_ids: Vec<BytesN<32>> = env.storage().persistent()
            .get(&DataKey::FleetZones(fleet_operator))
            .unwrap_or(Vec::new(&env));

        if zone_ids.is_empty() {
            // No restrictions if no zones assigned
            return true;
        }

        // Check if point is in any assigned zone
        for i in 0..zone_ids.len() {
            let zone_id = zone_ids.get(i).unwrap();
            if let Some(zone) = env.storage().persistent().get::<DataKey, CircularZone>(&DataKey::CircularZone(zone_id.clone())) {
                let distance = Self::calculate_distance(&zone.center, &point);
                if distance <= zone.radius_meters {
                    return true;
                }
            }
        }

        false
    }

    /// Link a station to a zone
    pub fn link_station_zone(
        env: Env,
        station_owner: Address,
        zone_id: BytesN<32>,
    ) {
        station_owner.require_auth();
        env.storage().persistent().set(&DataKey::StationZone(station_owner.clone()), &zone_id);

        env.events().publish(
            (Symbol::new(&env, "station_zone_linked"), station_owner),
            zone_id,
        );
    }

    /// Get a circular zone by ID
    pub fn get_circular_zone(env: Env, zone_id: BytesN<32>) -> CircularZone {
        env.storage().persistent()
            .get(&DataKey::CircularZone(zone_id))
            .expect("Zone not found")
    }

    /// Get a corridor by ID
    pub fn get_corridor(env: Env, corridor_id: BytesN<32>) -> Corridor {
        env.storage().persistent()
            .get(&DataKey::Corridor(corridor_id))
            .expect("Corridor not found")
    }

    /// Deactivate a zone
    pub fn deactivate_zone(env: Env, admin: Address, zone_id: BytesN<32>) {
        admin.require_auth();
        Self::require_admin(&env, &admin);

        if let Some(mut zone) = env.storage().persistent().get::<DataKey, CircularZone>(&DataKey::CircularZone(zone_id.clone())) {
            zone.is_active = false;
            env.storage().persistent().set(&DataKey::CircularZone(zone_id.clone()), &zone);
        }

        env.events().publish(
            (Symbol::new(&env, "zone_deactivated"), zone_id),
            true,
        );
    }

    /// Get total zone count
    pub fn get_zone_count(env: Env) -> u64 {
        env.storage().instance().get(&DataKey::ZoneCount).unwrap_or(0)
    }

    /// Get total corridor count
    pub fn get_corridor_count(env: Env) -> u64 {
        env.storage().instance().get(&DataKey::CorridorCount).unwrap_or(0)
    }

    /// Helper: Check admin authorization
    fn require_admin(env: &Env, address: &Address) {
        let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        if *address != admin {
            panic!("Unauthorized: not admin");
        }
    }
}

/// Pre-defined major EAC corridors
pub mod corridors {
    use super::*;

    /// Northern Corridor: Mombasa, Kenya to Kampala, Uganda
    pub fn northern_corridor(env: &Env) -> Corridor {
        let mut waypoints = Vec::new(env);
        // Nairobi waypoint
        waypoints.push_back(GeoPoint { lat: -1_286_389, lng: 36_817_222 });
        // Nakuru waypoint
        waypoints.push_back(GeoPoint { lat: -289_722, lng: 36_066_667 });
        // Eldoret waypoint
        waypoints.push_back(GeoPoint { lat: 518_056, lng: 35_269_722 });
        // Busia border waypoint
        waypoints.push_back(GeoPoint { lat: 460_000, lng: 34_110_000 });

        Corridor {
            id: BytesN::from_array(env, &[1u8; 32]),
            name: soroban_sdk::String::from_str(env, "Northern Corridor"),
            start_point: GeoPoint { lat: -4_043_500, lng: 39_668_200 }, // Mombasa
            end_point: GeoPoint { lat: 313_733, lng: 32_582_192 },      // Kampala
            waypoints,
            buffer_meters: 50_000, // 50km buffer
            is_active: true,
            created_at: 0,
        }
    }

    /// Central Corridor: Dar es Salaam, Tanzania to Kigali, Rwanda
    pub fn central_corridor(env: &Env) -> Corridor {
        let mut waypoints = Vec::new(env);
        // Dodoma waypoint
        waypoints.push_back(GeoPoint { lat: -6_172_944, lng: 35_739_722 });
        // Tabora waypoint
        waypoints.push_back(GeoPoint { lat: -5_010_278, lng: 32_826_389 });
        // Kigoma waypoint
        waypoints.push_back(GeoPoint { lat: -4_876_389, lng: 29_627_778 });

        Corridor {
            id: BytesN::from_array(env, &[2u8; 32]),
            name: soroban_sdk::String::from_str(env, "Central Corridor"),
            start_point: GeoPoint { lat: -6_792_354, lng: 39_208_328 }, // Dar es Salaam
            end_point: GeoPoint { lat: -1_940_278, lng: 29_873_889 },   // Kigali
            waypoints,
            buffer_meters: 50_000,
            is_active: true,
            created_at: 0,
        }
    }
}
