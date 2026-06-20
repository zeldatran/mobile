package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.Notification;
import com.trannguyendiemhanh.auth.service.NotificationService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController extends CrudController<Notification, UUID> {
    public NotificationController(NotificationService service) {
        super(service);
    }
}
