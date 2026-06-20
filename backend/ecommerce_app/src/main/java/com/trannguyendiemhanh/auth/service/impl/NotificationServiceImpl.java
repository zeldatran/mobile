package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.Notification;
import com.trannguyendiemhanh.auth.repository.NotificationRepository;
import com.trannguyendiemhanh.auth.service.NotificationService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class NotificationServiceImpl extends JpaCrudServiceImpl<Notification, UUID> implements NotificationService {
    public NotificationServiceImpl(NotificationRepository repository) {
        super(repository);
    }
}
