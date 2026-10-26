const maxRoomNameLength = 16;
const maxPlayerNameLength = 14;
const participantOptions = [2, 3, 4, 5];
const codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const codeLength = 4;

final validChars = RegExp(r'^[A-Za-z0-9 _.-]+$');

/// A person's name: starts with a letter, then letters, spaces, - ' or .
final validPlayerNameChars = RegExp(r"^[A-Za-z][A-Za-z '.-]*$");
