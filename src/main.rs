use bevy::{prelude::*, sprite::MaterialMesh2dBundle};


#[derive(Component)]
struct Person;

#[derive(Component)]
struct Name(String);

#[derive(Resource)]
struct GreetTimer(Timer);

pub struct HelloPlugin;


impl Plugin for HelloPlugin {
    fn build(&self, app: &mut App) {
        app.add_startup_system(add_people).add_system(greet_people);
    }
}


fn add_people(mut commands: Commands) {
    commands.spawn((Person, Name("Elaina Proctor".to_string())));
    commands.spawn((Person, Name("Renzo Hume".to_string())));
    commands.spawn((Person, Name("Zayna Nieves".to_string())));
}


fn greet_people(time: Res<Time>, mut timer: ResMut<GreetTimer>, query: Query<&Name, With<Person>>) {
    // update our timer with the time elapsed since the last update
    // if that caused the timer to finish, we say hello to everyone
    if timer.0.tick(time.delta()).just_finished() {
        for name in query.iter() {
            println!("hello {}!", name.0);
        }
    }
}


fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_plugin(HelloPlugin)
        .add_startup_system(setup)
        .run();
}


// from https://github.com/bevyengine/bevy/blob/latest/examples/2d/mesh2d.rs
fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<ColorMaterial>>,
) {
    commands.spawn(Camera2dBundle::default());
    commands.spawn(MaterialMesh2dBundle {
        mesh: meshes.add(Mesh::from(shape::Quad::default())).into(),
        transform: Transform::default().with_scale(Vec3::splat(128.)),
        material: materials.add(ColorMaterial::from(Color::PURPLE)),
        ..default()
    });
}
