use super::{
    image_cache::load_dmi,
    universal_icon::{UniversalIcon, UniversalIconData},
};
use base64::{engine::general_purpose::STANDARD, Engine};
use dmi::icon::Icon;
use image::ImageFormat;
use indexmap::IndexMap;
use meowtonin::{ByondError, ByondResult};
use std::{io::Cursor, sync::Arc};

#[derive(Default)]
struct PreviewRenderer {
    dmi: Option<(String, Arc<Icon>)>,
}

impl PreviewRenderer {
    fn render(&mut self, icon: &UniversalIcon) -> ByondResult<Arc<UniversalIconData>> {
        if self.dmi.as_ref().map(|(path, _)| path) != Some(&icon.icon_file) {
            self.dmi = None;
            self.dmi = Some((icon.icon_file.clone(), load_dmi(&icon.icon_file)?));
        }
        let mut data =
            icon.get_image_data_from_dmi(&icon.icon_state, true, &self.dmi.as_ref().unwrap().1)?;
        for transform in &icon.transform {
            data = Arc::new(transform.apply_with_loader(data, &mut |nested| self.render(nested))?);
        }
        Ok(data)
    }
}

pub fn generate_previews(sprites: &str) -> ByondResult<String> {
    let sprites: IndexMap<String, UniversalIcon> =
        serde_json::from_str(sprites).map_err(ByondError::boxed)?;
    let mut renderer = PreviewRenderer::default();
    let mut previews = IndexMap::new();
    for (name, icon) in sprites {
        let preview = renderer.render(&icon).and_then(|data| {
            let mut png = Cursor::new(Vec::new());
            data.images[0]
                .write_to(&mut png, ImageFormat::Png)
                .map_err(ByondError::boxed)?;
            Ok(STANDARD.encode(png.into_inner()))
        });
        previews.insert(name, preview.unwrap_or_default());
    }
    serde_json::to_string(&previews).map_err(ByondError::boxed)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::iconforge::{image_cache, universal_icon::Transform};

    fn fixture(file: &str, state: &str) -> UniversalIcon {
        UniversalIcon {
            icon_file: format!("{}/../icons/effects/{file}.dmi", env!("CARGO_MANIFEST_DIR")),
            icon_state: state.to_owned(),
            dir: Some(2),
            frame: Some(1),
            transform: vec![Transform::Scale {
                width: 32,
                height: 32,
            }],
        }
    }

    #[test]
    fn releases_decoded_dmis_when_switching_files() {
        let mut renderer = PreviewRenderer::default();
        let white = fixture("alphacolors", "white");
        renderer.render(&white).unwrap();
        let decoded = Arc::downgrade(&renderer.dmi.as_ref().unwrap().1);
        renderer.render(&fixture("effects", "nothing")).unwrap();
        assert!(decoded.upgrade().is_none());
        assert!(!image_cache::image_cache_contains(&white));
        let decoded = Arc::downgrade(&renderer.dmi.as_ref().unwrap().1);
        drop(renderer);
        assert!(decoded.upgrade().is_none());
    }

    #[test]
    fn nested_blends_and_colors_match_the_spritesheet_renderer() {
        let mut icon = fixture("alphacolors", "white");
        let mut overlay = fixture("alphacolors", "white");
        overlay.transform.push(Transform::BlendColor {
            color: "#ff000080".into(),
            blend_mode: 0,
        });
        icon.transform.push(Transform::BlendIcon {
            icon: overlay,
            blend_mode: 2,
            x: Some(1),
            y: Some(1),
        });
        let mut renderer = PreviewRenderer::default();
        let actual = renderer.render(&icon).unwrap();
        let (mut expected, _) = icon
            .get_image_data(&"preview test".into(), false, false, true)
            .unwrap();
        for transform in &icon.transform {
            expected = Arc::new(transform.apply(expected, true).unwrap());
        }
        assert_eq!(actual.images, expected.images);
        assert_eq!(actual.images[0].dimensions(), (32, 32));
    }

    #[test]
    fn missing_states_do_not_discard_other_previews() {
        let sprites = IndexMap::from([
            ("valid", fixture("alphacolors", "white")),
            (
                "missing",
                fixture("alphacolors", "__missing_preview_state__"),
            ),
        ]);
        let result = generate_previews(&serde_json::to_string(&sprites).unwrap()).unwrap();
        let previews: IndexMap<String, String> = serde_json::from_str(&result).unwrap();
        let png = STANDARD.decode(&previews["valid"]).unwrap();
        let image = image::load_from_memory(&png).unwrap();
        assert_eq!((image.width(), image.height()), (32, 32));
        assert!(previews["missing"].is_empty());
    }
}
