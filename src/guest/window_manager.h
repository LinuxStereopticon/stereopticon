/*
 * Copyright © 2021 Alfred Neumayer
 * Copyright © 2016-2018 Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 or 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored By:
 * - Alfred Neumayer <dev.beidl@gmail.com>
 * - Alan Griffiths <alan@octopull.co.uk>
 */

#ifndef WINDOWMANAGER_H
#define WINDOWMANAGER_H

#include <miral/canonical_window_manager.h>

#include <mir_toolkit/events/enums.h>

#include "../common/sender/guestpixelbuffersender.hpp"

using namespace mir::geometry;

class StereopticonWindowManagerPolicy : public miral::CanonicalWindowManagerPolicy
{
public:
    StereopticonWindowManagerPolicy(miral::WindowManagerTools const& tools, GuestPixelBufferSender& bufferSender);

    auto place_new_window(miral::ApplicationInfo const& app_info, miral::WindowSpecification const& request)
    -> miral::WindowSpecification override;

    void advise_new_window(miral::WindowInfo const& window_info) override;
    void advise_delete_window(miral::WindowInfo const& window_info) override;

    void advise_focus_gained(miral::WindowInfo const& info) override;

    bool handle_keyboard_event(MirKeyboardEvent const* event) override;
    bool handle_touch_event(MirTouchEvent const* event) override;
    bool handle_pointer_event(MirPointerEvent const* event) override;
    void handle_modify_window(miral::WindowInfo& window_info, miral::WindowSpecification const& modifications) override;

    void handle_request_drag_and_drop(miral::WindowInfo& window_info) override;
    void handle_request_move(miral::WindowInfo& window_info, MirInputEvent const* input_event) override;
    void handle_request_resize(miral::WindowInfo& window_info, MirInputEvent const* input_event,
        MirResizeEdge edge) override;

    Rectangle confirm_placement_on_display(const miral::WindowInfo& window_info, MirWindowState new_state,
        Rectangle const& new_placement) override;

private:
    GuestPixelBufferSender* m_hostComm = nullptr;
    static const int modifier_mask =
        mir_input_event_modifier_alt |
        mir_input_event_modifier_shift |
        mir_input_event_modifier_sym |
        mir_input_event_modifier_ctrl |
        mir_input_event_modifier_meta;
};

#endif
