package com.trannguyendiemhanh.auth.repository;

import com.trannguyendiemhanh.auth.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, UUID> {}
