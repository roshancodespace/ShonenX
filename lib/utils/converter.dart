String getHighResImage(String posterUrl) {
  return posterUrl.replaceAll(RegExp(r'(\d+)x(\d+)'), '600x800');
}
