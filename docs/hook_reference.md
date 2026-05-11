# Hook Reference

This document lists the current stable hook and filter names used by goLaPress and the payload type each hook emits.

All hook payloads are JSON-encoded.

## Auth Events

- `auth.login`: `AuthEventPayload`
- `auth.logout`: `AuthEventPayload`
- `auth.password_reset.requested`: `AuthEventPayload`
- `auth.password_reset.completed`: `AuthEventPayload`
- `auth.session.revoked`: `AuthEventPayload`
- `auth.user.created`: `UserEventPayload`
- `auth.user.updated`: `UserEventPayload`
- `auth.user.role_changed`: `UserEventPayload`

## Content Events

- `content.page.created`: `ContentEventPayload`
- `content.page.updated`: `ContentEventPayload`
- `content.page.deleted`: `ContentEventPayload`
- `content.page.published`: `ContentEventPayload`
- `content.page.unpublished`: `ContentEventPayload`
- `content.post.created`: `ContentEventPayload`
- `content.post.updated`: `ContentEventPayload`
- `content.post.deleted`: `ContentEventPayload`
- `content.post.published`: `ContentEventPayload`
- `content.post.unpublished`: `ContentEventPayload`
- `content.category.created`: `CategoryEventPayload`
- `content.category.updated`: `CategoryEventPayload`
- `content.category.deleted`: `CategoryEventPayload`

## Media Events

- `media.created`: `MediaEventPayload`
- `media.updated`: `MediaEventPayload`
- `media.deleted`: `MediaEventPayload`

## Plugin Events

- `plugin.activated`: `PluginEventPayload`
- `plugin.deactivated`: `PluginEventPayload`
- `plugin.settings.updated`: `PluginEventPayload`
- `plugin.unavailable`: `PluginEventPayload`

## Theme Events

- `theme.activated`: `ThemeEventPayload`
- `theme.installed`: `ThemeEventPayload`
- `theme.imported`: `ThemeEventPayload`
- `theme.deleted`: `ThemeEventPayload`
- `theme.upload.rejected`: `ThemeEventPayload`

## Commerce Events

- `commerce.order.created`: `CommerceEventPayload`
- `commerce.order.paid`: `CommerceEventPayload`
- `commerce.order.cancelled`: `CommerceEventPayload`
- `commerce.order.refunded`: `CommerceEventPayload`
- `commerce.order.note_added`: `CommerceEventPayload`

## Filters

- `render.context.filter`: `ThemeRenderEventPayload` plus a render-context payload owned by the host

## Payload Types

### `Actor`

Fields:

- `UserID`
- `Email`
- `Role`
- `SessionID`

### `AuthEventPayload`

Fields:

- `Actor`
- `Action`
- `UserID`
- `Email`
- `Role`
- `SessionID`

### `UserEventPayload`

Fields:

- `Actor`
- `Action`
- `UserID`
- `Email`
- `DisplayName`
- `Role`
- `PreviousRole`
- `PasswordChanged`
- `SelfService`

### `ThemeRenderEventPayload`

Fields:

- `Actor`
- `Preview`
- `RouteKind`
- `ThemeID`
- `TemplatePath`
- `ContentType`
- `ContentID`
- `Slug`

### `SEOData`

Fields:

- `Title`
- `Description`
- `CanonicalURL`
- `Robots`
- `OpenGraphTitle`
- `OpenGraphDescription`
- `OpenGraphType`
- `OpenGraphURL`
- `OpenGraphImageURL`
- `TwitterCard`
- `TwitterTitle`
- `TwitterDescription`
- `TwitterImageURL`

### `ContentEventPayload`

Fields:

- `Actor`
- `Action`
- `ContentType`
- `ID`
- `Slug`
- `Title`
- `Status`
- `FeaturedMediaID`
- `CategorySlugs`
- `PreviousSlug`
- `PreviousTitle`
- `PreviousStatus`
- `PreviousFeaturedMediaID`
- `PreviousCategorySlugs`

### `CategoryEventPayload`

Fields:

- `Actor`
- `Action`
- `ID`
- `Slug`
- `Name`
- `Description`
- `PostCount`

### `MediaEventPayload`

Fields:

- `Actor`
- `Action`
- `ID`
- `Filename`
- `ContentType`
- `SizeBytes`
- `AltText`
- `Caption`
- `Description`
- `URL`

### `PluginEventPayload`

Fields:

- `Actor`
- `Action`
- `ID`
- `Name`
- `Version`
- `Builtin`
- `Enabled`
- `SettingName`
- `ErrorMessage`

### `ThemeEventPayload`

Fields:

- `Actor`
- `Action`
- `SourceType`
- `ID`
- `Name`
- `Version`
- `PreviousID`
- `PreviousName`
- `PreviousVersion`
- `ErrorMessage`

### `CommerceEventPayload`

Fields:

- `Actor`
- `PluginID`
- `Action`
- `OrderID`
- `OrderNumber`
- `CustomerID`
- `CustomerEmail`
- `Currency`
- `Total`
- `Status`
- `PreviousStatus`
- `NoteID`
- `Reason`
- `Metadata`
