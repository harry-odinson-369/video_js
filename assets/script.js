let pendingUpdate = false;
window.addEventListener("DOMContentLoaded", () => {
  const getBufferedRanges = (videoEl) => {
    const video = videoEl || document.querySelector("video");
    const buffered = video.buffered;
    const result = [];
    for (let i = 0; i < buffered.length; i++) {
      result.push({
        start: buffered.start(i),
        end: buffered.end(i),
      });
    }
    return result;
  };
  const errMsg = () => {
    const code = document.querySelector("video").error.code;
    return (
      [
        "MEDIA_ERR_ABORTED",
        "MEDIA_ERR_NETWORK",
        "MEDIA_ERR_DECODE",
        "MEDIA_ERR_SRC_NOT_SUPPORTED",
      ][code - 1] || "UNEXPECTED_ERROR"
    );
  };
  const getUrlProperties = () => {
    const url = new URL(location.href);
    const decoded = atob(url.searchParams.get("props"));
    let props = JSON.parse(decoded);
    if (typeof props === "string") {
      props = JSON.parse(props);
    }
    return {
      src: props.src,
      autoplay: props.autoplay,
      headers: props.headers,
      type: props.type,
      poster: props.poster,
    };
  };
  const socket = new WebSocket(`ws://${location.host}/ws`);
  socket.onopen = (_) => {
    function sendValue(extra = {}, ele) {
      if (pendingUpdate) return;
      if (socket.readyState === WebSocket.OPEN) {
        pendingUpdate = true;
        const el = ele || document.querySelector("video");
        let data = {
          state: "idle",
          initialized: el.readyState > 0,
          buffered: getBufferedRanges(el),
          duration: el.duration,
          current: el.currentTime,
          loop: el.loop,
          volume: el.volume,
          speed: el.playbackRate,
          size: {
            width: el.videoWidth,
            height: el.videoHeight,
          },
          ...extra,
        };
        socket.send(JSON.stringify(data));
        window.pre_value = data;
        pendingUpdate = false;
      }
    }
    const props = getUrlProperties();
    document.querySelector("video").autoplay = props.autoplay;
    document.querySelector("video").poster = props.poster;
    const player = videojs(document.querySelector("video"));
    player.src({ src: props.src, type: props.type });
    document.querySelector("video").addEventListener("loadedmetadata", () => {
      sendValue({
        initialized: true,
        state: "ready",
      });
    });
    document.querySelector("video").addEventListener("waiting", () => {
      sendValue({
        state: "buffering",
      });
    });
    document.querySelector("video").addEventListener("playing", () => {
      sendValue({
        state: "playing",
      });
    });
    document.querySelector("video").addEventListener("pause", () => {
      sendValue({
        state: "paused",
      });
    });
    document.querySelector("video").addEventListener("timeupdate", () => {
      sendValue({
        state: "playing",
      });
    });
    document.querySelector("video").addEventListener("ended", () => {
      sendValue({
        state: "ended",
      });
    });
    document.querySelector("video").addEventListener("error", () => {
      sendValue({
        error: errMsg(),
        state: "error",
      });
    });
    socket.onmessage = (event) => {
      let data = JSON.parse(event.data);
      if (typeof data === "string") {
        data = JSON.parse(event.data);
      }
      var el = document.querySelector("video");
      if (data.action === "play") {
        el.play();
      } else if (data.action === "pause") {
        el.pause();
      } else if (data.action === "seek") {
        el.currentTime = data.position;
      } else if (data.action === "speed") {
        el.playbackRate = data.rate;
      } else if (data.action === "volume") {
        el.volume = data.level;
      } else if (data.action === "loop") {
        el.loop = data.allow;
      }
    };
  };
});
