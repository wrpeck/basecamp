{{flutter_js}}
{{flutter_build_config}}

// Serve CanvasKit from the bundle instead of the gstatic CDN so the app
// renders even where that CDN is unreachable.
_flutter.loader.load({
  config: { canvasKitBaseUrl: "canvaskit/" },
});
