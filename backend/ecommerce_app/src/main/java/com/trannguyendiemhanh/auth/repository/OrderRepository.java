package com.trannguyendiemhanh.auth.repository;

import com.trannguyendiemhanh.auth.entity.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OrderRepository extends JpaRepository<Order, String> {}
